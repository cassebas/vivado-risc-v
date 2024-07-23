library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fiforeader_axilite is
  generic (
    ADDR_WIDTH : integer := 16;
    DATA_WIDTH : integer := 32);
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    -- DEBUG leds
    leds : out std_logic_vector(7 downto 0);
    -- FIFO ports
    fifo_empty_i : in std_logic;
    fifo_dout_i  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_rden_o  : out std_logic;
    --
    -- AXI Lite master ports
    --
    -- AXI Lite Write Request channel
    M_AXI_awaddr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M_AXI_awvalid : out std_logic;
    M_AXI_awready : in std_logic;
    -- AXI Lite Write Data channel
    M_AXI_wdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    M_AXI_wvalid  : out std_logic;
    M_AXI_wready  : in std_logic;
    -- AXI Lite Write Response channel
    M_AXI_bresp   : in std_logic_vector(1 downto 0);
    M_AXI_bvalid  : in std_logic;
    M_AXI_bready  : out std_logic;
    -- AXI Lite Read Request channel
    M_AXI_araddr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M_AXI_arvalid : out std_logic;
    M_AXI_arready : in std_logic;
    -- AXI Lite Read Data channel
    M_AXI_rdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    M_AXI_rresp   : in std_logic_vector(1 downto 0);
    M_AXI_rvalid  : in std_logic;
    M_AXI_rready  : out std_logic);
end fiforeader_axilite;

architecture behaviour of fiforeader_axilite is

  function convert_to_ascii(nibble : std_logic_vector(3 downto 0))
    return std_logic_vector is
  begin
    case nibble is
      when "0000" => return "00110000"; -- '0' (ASCII: 48)
      when "0001" => return "00110001"; -- '1' (ASCII: 49)
      when "0010" => return "00110010"; -- '2' (ASCII: 50)
      when "0011" => return "00110011"; -- '3' (ASCII: 51)
      when "0100" => return "00110100"; -- '4' (ASCII: 52)
      when "0101" => return "00110101"; -- '5' (ASCII: 53)
      when "0110" => return "00110110"; -- '6' (ASCII: 54)
      when "0111" => return "00110111"; -- '7' (ASCII: 55)
      when "1000" => return "00111000"; -- '8' (ASCII: 56)
      when "1001" => return "00111001"; -- '9' (ASCII: 57)
      when "1010" => return "01100001"; -- 'a' (ASCII: 97)
      when "1011" => return "01100010"; -- 'b' (ASCII: 98)
      when "1100" => return "01100011"; -- 'c' (ASCII: 99)
      when "1101" => return "01100100"; -- 'd' (ASCII: 100)
      when "1110" => return "01100101"; -- 'e' (ASCII: 101)
      when "1111" => return "01100110"; -- 'f' (ASCII: 102)
    end case;
  end function convert_to_ascii;

  -- Input data received from the FIFO
  signal fifo_dreg : std_logic_vector(DATA_WIDTH-1 downto 0);

  type fifo_read_state_type is (FIFO_IDLE,
                                FIFO_ENABLE,
                                FIFO_READY);
  signal fifo_read_state, fifo_read_state_nxt : fifo_read_state_type;

  type axi_lite_state_type is (AXI_IDLE,
                               AXI_READ_REQ,
                               AXI_READ_DATA,
                               AXI_WRITE_REQ_DATA,
                               AXI_WRITE_RESP);
  signal axi_lite_state, axi_lite_state_nxt : axi_lite_state_type;

  -- The data will be sent by 4 bits per transfer, because we want to print
  -- them as hexademicals encoded with ascii characters. Each address is
  -- 32 bits wide, so we need 8 nibbles.
  signal send_nibble_state, send_nibble_state_nxt : unsigned(3 downto 0);
  constant ZERO : unsigned(3 downto 0) := "1011";
  constant HEXX : unsigned(3 downto 0) := "1010";
  -- Most significant nibble
  constant NIB7 : unsigned(3 downto 0) := "1001";
  constant NIB6 : unsigned(3 downto 0) := "1000";
  constant NIB5 : unsigned(3 downto 0) := "0111";
  constant NIB4 : unsigned(3 downto 0) := "0110";
  constant NIB3 : unsigned(3 downto 0) := "0101";
  constant NIB2 : unsigned(3 downto 0) := "0100";
  constant NIB1 : unsigned(3 downto 0) := "0011";
  -- Least significant nibble
  constant NIB0 : unsigned(3 downto 0) := "0010";
  constant NEWL : unsigned(3 downto 0) := "0001";
  constant CRET : unsigned(3 downto 0) := "0000";

  --
  -- AXI Lite signals
  --
  -- AXI Lite Write Request channel
  signal axi_awaddr  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal axi_awvalid : std_logic;
  -- AXI Lite Write Data channel
  signal axi_wdata   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal axi_wvalid  : std_logic;
  -- AXI Lite Write Response channel
  signal axi_bready  : std_logic;
  -- AXI Lite Read Request channel
  signal axi_araddr  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal axi_arvalid : std_logic;
  signal axi_rdata   : std_logic_vector(DATA_WIDTH-1 downto 0);
  -- AXI Lite Read Data channel
  signal axi_rready  : std_logic;

  -- Read from UART: address is 4'h08
  constant AXI_READ_STATUS_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0) :=
    (3 => '1', others => '0');
  -- Write to UART tx buffer: address is 4'h04
  constant AXI_WRITE_TXBUF_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0) :=
    (2 => '1', others => '0');
  -- Write to UART control register: address is 4'h0c
  constant AXI_WRITE_CONTROL_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0) :=
    (3 => '1', 2 => '1', others => '0');

begin

  statemachine_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      fifo_read_state <= FIFO_IDLE;
      send_nibble_state <= ZERO;
      axi_lite_state <= AXI_IDLE;
    elsif rising_edge(clk) then
      fifo_read_state <= fifo_read_state_nxt;
      send_nibble_state <= send_nibble_state_nxt;
      axi_lite_state <= axi_lite_state_nxt;
    end if;
  end process statemachine_register;


  read_fifo_statemachine_decoder : process(fifo_read_state, send_nibble_state,
                                           axi_lite_state, fifo_empty_i) is
  begin
    fifo_read_state_nxt <= fifo_read_state;
    case fifo_read_state is
      when FIFO_IDLE =>
        if fifo_empty_i = '0' then
          fifo_read_state_nxt <= FIFO_ENABLE;
        end if;
      when FIFO_ENABLE =>
        fifo_read_state_nxt <= FIFO_READY;
      when FIFO_READY =>
        if axi_lite_state = AXI_WRITE_RESP and M_AXI_bvalid = '1' then
          if send_nibble_state = CRET then
            fifo_read_state_nxt <= FIFO_IDLE;
          end if;
        end if;
    end case;
  end process read_fifo_statemachine_decoder;


  read_fifo_output_decoder : process(fifo_read_state) is
  begin
    case fifo_read_state is
      when FIFO_IDLE =>
        fifo_rden_o <= '0';
      when FIFO_ENABLE =>
        fifo_rden_o <= '1';
      when FIFO_READY =>
        fifo_rden_o <= '0';
    end case;
  end process read_fifo_output_decoder;


  read_fifo : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      fifo_dreg <= (others => '0');
    elsif rising_edge(clk) then
      if fifo_read_state = FIFO_ENABLE then
        fifo_dreg <= fifo_dout_i;
      end if;
    end if;
  end process read_fifo;


  send_nibble_statemachine_decoder : process(send_nibble_state, axi_lite_state,
                                             M_AXI_bvalid) is
  begin
    if axi_lite_state = AXI_WRITE_RESP and M_AXI_bvalid = '1' then
      if send_nibble_state = CRET then
        send_nibble_state_nxt <= ZERO;
      else
        send_nibble_state_nxt <= send_nibble_state - 1;
      end if;
    else
      send_nibble_state_nxt <= send_nibble_state;
    end if;
  end process send_nibble_statemachine_decoder;


  axi_lite_statemachine_decoder : process(axi_lite_state, fifo_read_state,
                                          M_AXI_rdata, M_AXI_rvalid,
                                          M_AXI_bvalid) is
  begin
    axi_lite_state_nxt <= axi_lite_state;
    case axi_lite_state is
      when AXI_IDLE =>
        if fifo_read_state = FIFO_READY then
          axi_lite_state_nxt <= AXI_READ_REQ;
        end if;
      when AXI_READ_REQ =>
        axi_lite_state_nxt <= AXI_READ_DATA;
      when AXI_READ_DATA =>
        if M_AXI_rvalid = '1' then
          if M_AXI_rdata(3) /= '1' then
            axi_lite_state_nxt <= AXI_WRITE_REQ_DATA;
          else
            axi_lite_state_nxt <= AXI_READ_REQ;
          end if;
        end if;
      when AXI_WRITE_REQ_DATA =>
        axi_lite_state_nxt <= AXI_WRITE_RESP;
      when AXI_WRITE_RESP =>
        if M_AXI_bvalid = '1' then
          if send_nibble_state = CRET then
            axi_lite_state_nxt <= AXI_IDLE;
          else
            axi_lite_state_nxt <= AXI_READ_REQ;
          end if;
        end if;
    end case;
  end process axi_lite_statemachine_decoder;


  axi_lite_output_decoder : process(clk, rst_n) is
    variable ascii : std_logic_vector(7 downto 0);
  begin
    if rst_n = '0' then
      -- AXI Lite Write Request channel
      axi_awaddr <= (others => '0');
      axi_awvalid <= '0';
      -- AXI Lite Write Data channel
      axi_wdata <= (others => '0');
      axi_wvalid <= '0';
      -- AXI Lite Write Response channel
      axi_bready <= '0';
      -- AXI Lite Read Request channel
      axi_araddr <= (others => '0');
      axi_arvalid <= '0';
      -- AXI Lite Read Data channel
      axi_rready <= '0';
    elsif rising_edge(clk) then
      case axi_lite_state is
        when AXI_IDLE =>
          axi_awaddr <= (others => '0');
          axi_awvalid <= '0';
          axi_wdata <= (others => '0');
          axi_wvalid <= '0';
          axi_bready <= '0';
          axi_araddr <= (others => '0');
          axi_arvalid <= '0';
          axi_rready <= '0';
        when AXI_READ_REQ =>
          axi_araddr <= AXI_READ_STATUS_ADDR;
          axi_arvalid <= '1';
        when AXI_READ_DATA =>
          if M_AXI_rvalid = '1' then
            axi_rdata <= M_AXI_rdata;
            axi_rready <= '1';
            axi_araddr <= (others => '0');
            axi_arvalid <= '0';
          end if;
        when AXI_WRITE_REQ_DATA =>
          axi_awaddr <= AXI_WRITE_TXBUF_ADDR;
          axi_awvalid <= '1';
          axi_wdata(DATA_WIDTH-1 downto 8) <= (others => '0');
          case send_nibble_state is
            when ZERO => ascii := "00110000"; -- '0' (ASCII: 48)
            when HEXX => ascii := "01111000"; -- 'x' (ASCII: 120)
            when NIB7 => ascii := convert_to_ascii(fifo_dreg(31 downto 28));
            when NIB6 => ascii := convert_to_ascii(fifo_dreg(27 downto 24));
            when NIB5 => ascii := convert_to_ascii(fifo_dreg(23 downto 20));
            when NIB4 => ascii := convert_to_ascii(fifo_dreg(19 downto 16));
            when NIB3 => ascii := convert_to_ascii(fifo_dreg(15 downto 12));
            when NIB2 => ascii := convert_to_ascii(fifo_dreg(11 downto 8));
            when NIB1 => ascii := convert_to_ascii(fifo_dreg(7 downto 4));
            when NIB0 => ascii := convert_to_ascii(fifo_dreg(3 downto 0));
            when NEWL => ascii := "00001010"; -- LF (ASCII: 10)
            -- send_nibble_state can now only be CRET
            when others => ascii := "00001101"; -- CR (ASCII: 13)
          end case;
          axi_wdata(7 downto 0) <= ascii;

          axi_wvalid <= '1';
          axi_bready <= '1';
        when AXI_WRITE_RESP =>
          if M_AXI_bvalid = '1' then
            axi_awaddr <= (others => '0');
            axi_awvalid <= '0';
            axi_wdata <= (others => '0');
            axi_wvalid <= '0';
            axi_bready <= '0';
          end if;
      end case;
    end if;
  end process axi_lite_output_decoder;

  --
  -- AXI Lite outputs connected to registers
  --
  -- AXI Lite Write Request channel
  M_AXI_awaddr <= axi_awaddr;
  M_AXI_awvalid <= axi_awvalid;
  -- AXI Lite Write Data channel
  M_AXI_wdata <= axi_wdata;
  M_AXI_wvalid <= axi_wvalid;
  -- AXI Lite Write Response channel
  M_AXI_bready <= axi_bready;
  -- AXI Lite Read Request channel
  M_AXI_araddr <= axi_araddr;
  M_AXI_arvalid <= axi_arvalid;
  -- AXI Lite Read Data channel
  M_AXI_rready <= axi_rready;

end architecture behaviour;
