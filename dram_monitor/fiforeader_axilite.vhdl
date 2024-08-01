library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fiforeader_axilite is
  generic (
    UART_ADDR_WIDTH : integer := 16;
    UART_DATA_WIDTH : integer := 32;
    FIFO_DATA_WIDTH : integer := 180);
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    -- DEBUG leds
    leds : out std_logic_vector(7 downto 0);
    -- FIFO ports
    fifo_empty_i : in std_logic;
    fifo_dout_i  : in std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);
    fifo_rden_o  : out std_logic;
    --
    -- AXI Lite master ports
    --
    -- AXI Lite Write Request channel
    M_AXI_awaddr  : out std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
    M_AXI_awvalid : out std_logic;
    M_AXI_awready : in std_logic;
    -- AXI Lite Write Data channel
    M_AXI_wdata   : out std_logic_vector(UART_DATA_WIDTH-1 downto 0);
    M_AXI_wvalid  : out std_logic;
    M_AXI_wready  : in std_logic;
    -- AXI Lite Write Response channel
    M_AXI_bresp   : in std_logic_vector(1 downto 0);
    M_AXI_bvalid  : in std_logic;
    M_AXI_bready  : out std_logic;
    -- AXI Lite Read Request channel
    M_AXI_araddr  : out std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
    M_AXI_arvalid : out std_logic;
    M_AXI_arready : in std_logic;
    -- AXI Lite Read Data channel
    M_AXI_rdata   : in std_logic_vector(UART_DATA_WIDTH-1 downto 0);
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
  signal fifo_dreg : std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);
  signal fifo_tmp  : std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);

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

  -- The data will be sent to the terminal by 4 bits per transfer,
  -- because we want to print them as hexademicals encoded with
  -- ascii characters.
  -- Including some print characters we need 61 states.
  constant NIBBLE_STATE_LEN    : integer := 6;
  signal send_nibble_state     : unsigned(NIBBLE_STATE_LEN-1 downto 0);
  signal send_nibble_state_nxt : unsigned(NIBBLE_STATE_LEN-1 downto 0);
  -- Some named constants at fixed positions to be printed
  constant NUL1 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "000000"; -- 0
  constant HEX1 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "000001"; -- 1
  -- event number (16 bits, nibbles 2 - 5)
  constant SP1  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "000110"; -- 6
  constant NUL2 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "000111"; -- 7
  constant HEX2 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "001000"; -- 8
  -- cycle count at memory request (32 bits, nibbles 9 - 16)
  constant SP2  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "010001"; -- 17
  constant NUL3 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "010010"; -- 18
  constant HEX3 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "010011"; -- 19
  -- cycle count at returning data (32 bits, nibbles 20 - 27)
  constant SP3  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "011100"; -- 28
  constant NUL4 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "011101"; -- 29
  constant HEX4 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "011110"; -- 30
  -- arid (4 bits, nibble 31)
  constant SP4  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "100000"; -- 32
  constant NUL5 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "100001"; -- 33
  constant HEX5 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "100010"; -- 34
  -- request address (32 bits, nibbles 35-42)
  constant SP5  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "101011"; -- 43
  constant NUL6 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "101100"; -- 44
  constant HEX6 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "101101"; -- 45
  -- data (64 bits, nibbles 46-61)
  constant LF   : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "111110"; -- 62
  constant CR   : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "111111"; -- 63

  --
  -- AXI Lite signals
  --
  -- AXI Lite Write Request channel
  signal axi_awaddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_awvalid : std_logic;
  -- AXI Lite Write Data channel
  signal axi_wdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  signal axi_wvalid  : std_logic;
  -- AXI Lite Write Response channel
  signal axi_bready  : std_logic;
  -- AXI Lite Read Request channel
  signal axi_araddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_arvalid : std_logic;
  signal axi_rdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  -- AXI Lite Read Data channel
  signal axi_rready  : std_logic;

  -- Read from UART: address is 4'h08
  constant AXI_READ_STATUS_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', others => '0');
  -- Write to UART tx buffer: address is 4'h04
  constant AXI_WRITE_TXBUF_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (2 => '1', others => '0');
  -- Write to UART control register: address is 4'h0c
  constant AXI_WRITE_CONTROL_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', 2 => '1', others => '0');

begin

  statemachine_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      fifo_read_state <= FIFO_IDLE;
      send_nibble_state <= NUL1;
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
          if send_nibble_state = CR then
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
      if send_nibble_state = CR then
        send_nibble_state_nxt <= NUL1;
      else
        send_nibble_state_nxt <= send_nibble_state + 1;
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
          if send_nibble_state = CR then
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

      fifo_tmp <= (others => '0');
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
          -- In this state, the read_fifo_state must be FIFO_READY
          if send_nibble_state = NUL1 then
            -- Only copy fifo_tmp once
            fifo_tmp <= fifo_dreg;
          end if;
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
          axi_wdata(UART_DATA_WIDTH-1 downto 8) <= (others => '0');

          case send_nibble_state is
            when NUL1 | NUL2 | NUL3 | NUL4 | NUL5 | NUL6 =>
              ascii := "00110000"; -- '0' (ASCII: 48)
            when HEX1 | HEX2 | HEX3 | HEX4 | HEX5 |HEX6 =>
              ascii := "01111000"; -- 'x' (ASCII: 120)
            when SP1 | SP2 | SP3 | SP4 | SP5  =>
              ascii := "00100000"; -- ' ' (ASCII: 32)
            when LF   =>
              ascii := "00001010"; -- LF (ASCII: 10)
            when CR   =>
              ascii := "00001101"; -- CR (ASCII: 13)
            when others =>
              ascii := convert_to_ascii(fifo_tmp(179 downto 176));
              -- Left-shift fifo_tmp 4 bits
              for k in fifo_tmp'high downto fifo_tmp'low+4 loop
                fifo_tmp(k) <= fifo_tmp(k - 4);
              end loop;
              fifo_tmp(3 downto 0) <= (others => '0');
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
