library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fiforeader_axilite is
  generic (
    ADDR_WIDTH      : integer := 32;
    UART_ADDR_WIDTH : integer := 16;
    UART_DATA_WIDTH : integer := 32;
    FIFO_DATA_WIDTH : integer := 181);
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    -- DEBUG leds
    leds : out std_logic_vector(7 downto 0);

    -- Bus analyzer configuration signals
    --
    -- monitor enable: enable/disable read/write transactions
    --   0x00 -> monitor OFF
    --   0x01 -> monitor read transactions only
    --   0x10 -> monitor write transactions only
    --   0x11 -> monitor both read/write transactions
    monitor_en_o    : out std_logic_vector(1 downto 0);
    -- address filter: filter transactions on start/end addresses
    --   0x0  -> filter disabled, all addresses are monitored
    --   0x1  -> filter enabled, only start en end addresses are monitored
    addr_filter_o   : out std_logic;
    -- address monitor start and end addresses
    --   addr1_monitor_o -> start address to monitor
    --   addr2_monitor_o -> end address to monitor
    addr1_monitor_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    addr2_monitor_o : out std_logic_vector(ADDR_WIDTH-1 downto 0);

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
      when others => return "00101010"; -- '*' (ASCII: 42)
    end case;
  end function convert_to_ascii;

  -- Input data received from the FIFO
  signal fifo_dreg : std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);
  signal fifo_tmp  : std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);
  signal fifo_dreg_loaded : std_logic;

  type fifo_read_state_type is (FIFO_IDLE,
                                FIFO_ENABLE,
                                FIFO_READY);
  signal fifo_read_state, fifo_read_state_nxt : fifo_read_state_type;

  type axi_lite_state_type is (AXI_IDLE,
                               AXI_READ_REQ_STATUS,
                               AXI_READ_REQ_BUFFER,
                               AXI_READ_DATA_STATUS,
                               AXI_READ_DATA_BUFFER,
                               AXI_WRITE_REQ_DATA,
                               AXI_WRITE_RESP);
  signal axi_lite_r_state, axi_lite_r_state_nxt : axi_lite_state_type;
  signal axi_lite_w_state, axi_lite_w_state_nxt : axi_lite_state_type;

  -- The data will be sent to the terminal by 4 bits per transfer,
  -- because we want to print them as hexademicals encoded with
  -- ascii characters.
  -- Including some print characters we need 66 states.
  constant NIBBLE_STATE_LEN    : integer := 7;
  signal send_nibble_state     : unsigned(NIBBLE_STATE_LEN-1 downto 0);
  signal send_nibble_state_nxt : unsigned(NIBBLE_STATE_LEN-1 downto 0);
  -- Some named constants at fixed positions to be printed
  constant RWCH : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0000000"; -- 0
  constant SP1  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0000001"; -- 1
  constant NUL1 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0000010"; -- 2
  constant HEX1 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0000011"; -- 3
  -- event number (16 bits = 4 nibbles, states 4 - 7)
  constant SP2  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0001000"; -- 8
  constant NUL2 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0001001"; -- 9
  constant HEX2 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0001010"; -- 10
  -- cycle count at memory request (32 bits = 8 nibbles, states 11 - 18)
  constant SP3  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0010011"; -- 19
  constant NUL3 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0010100"; -- 20
  constant HEX3 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0010101"; -- 21
  -- cycle count at returning data (32 bits = 8 nibbles, states 22 - 29)
  constant SP4  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0011110"; -- 30
  constant NUL4 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0011111"; -- 31
  constant HEX4 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0100000"; -- 32
  -- arid (4 bits = 1 nibble, state 33)
  constant SP5  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0100010"; -- 34
  constant NUL5 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0100011"; -- 35
  constant HEX5 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0100100"; -- 36
  -- request address (32 bits = 8 nibbles, states 37-44)
  constant SP6  : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0101101"; -- 45
  constant NUL6 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0101110"; -- 46
  constant HEX6 : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "0101111"; -- 47
  -- data (64 bits = 16 nibbles, states 48-63)
  constant CR   : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "1000000"; -- 64
  constant LF   : unsigned(NIBBLE_STATE_LEN-1 downto 0) := "1000001"; -- 65

  -- Definition of ascii characters, to denote whether a transfer
  -- was a read transacation or a write transaction.
  --
  -- 'R' (read, decimal ascii: 82)
  constant r_ascii : std_logic_vector(7 downto 0) := "01010010";
  -- 'W' (write, decimal ascii: 87)
  constant w_ascii : std_logic_vector(7 downto 0) := "01010111";
  -- 'U' (unknown, decimal ascii: 86)
  constant u_ascii : std_logic_vector(7 downto 0) := "01010110";
  --
  -- A single bit will be put into the FIFO for the type of transaction.
  constant rd_transaction : std_logic := '0';
  constant wr_transaction : std_logic := '1';

  --
  -- Determination of the addresses that must be monitored by AXI passthrough
  --
  -- Default values for the addresses to monitor by the AXI passthrough
  constant mon_en_def : std_logic_vector(7 downto 0) := x"00";
  constant flt_en_def : std_logic_vector(7 downto 0) := x"00";
  constant addr1_def  : std_logic_vector(ADDR_WIDTH-1 downto 0) := x"00001180";
  constant addr2_def  : std_logic_vector(ADDR_WIDTH-1 downto 0) := x"00001100";
  signal rcv_reg : std_logic_vector((ADDR_WIDTH*2)-1+16 downto 0);
  signal rcv_tmp : std_logic_vector((ADDR_WIDTH*2)-1+16 downto 0);
  signal rcv_tmp_ready : std_logic;

  -- For counting the received bytes we will need 4 bits, because a
  -- maximum of 10 bytes will be received.
  -- The bytes received are:
  --  B9      -> monitor enable byte
  --  B8      -> address filter enable byte
  --  B7 - B4 -> 32-bit address, representing start function address
  --  B3 - B0 -> 32-bit address, representing end function address
  signal rx_bytecnt_state, rx_bytecnt_state_nxt : unsigned(3 downto 0);
  constant RX_B0 : unsigned(3 downto 0) := "0000";
  constant RX_B9 : unsigned(3 downto 0) := "1001";
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
  -- AXI Lite Read Data channel
  signal axi_rready  : std_logic;

  -- Read from UART rx buffer: address is 4'h00
  constant AXI_READ_RXBUFFER_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (others => '0');
  -- Write to UART tx buffer: address is 4'h04
  constant AXI_WRITE_TXBUF_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (2 => '1', others => '0');
  -- Read from UART status register: address is 4'h08
  constant AXI_READ_STATUS_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', others => '0');
  -- Write to UART control register: address is 4'h0c
  constant AXI_WRITE_CONTROL_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', 2 => '1', others => '0');

begin

  statemachine_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      fifo_read_state <= FIFO_IDLE;
      rx_bytecnt_state <= RX_B0;
      send_nibble_state <= RWCH;
      axi_lite_r_state <= AXI_IDLE;
      axi_lite_w_state <= AXI_IDLE;
    elsif rising_edge(clk) then
      fifo_read_state <= fifo_read_state_nxt;
      rx_bytecnt_state <= rx_bytecnt_state_nxt;
      send_nibble_state <= send_nibble_state_nxt;
      axi_lite_r_state <= axi_lite_r_state_nxt;
      axi_lite_w_state <= axi_lite_w_state_nxt;
    end if;
  end process statemachine_register;


  fifo_read_statemachine_decoder : process(fifo_read_state, send_nibble_state,
                                           axi_lite_w_state, fifo_empty_i,
                                           M_AXI_bvalid) is
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
        if axi_lite_w_state = AXI_WRITE_RESP and M_AXI_bvalid = '1' then
          if send_nibble_state = CR then
            if fifo_empty_i = '0' then
              fifo_read_state_nxt <= FIFO_ENABLE;
            else
              fifo_read_state_nxt <= FIFO_IDLE;
            end if;
          end if;
        end if;
    end case;
  end process fifo_read_statemachine_decoder;


  fifo_read_output_decoder : process(fifo_read_state) is
  begin
    case fifo_read_state is
      when FIFO_IDLE =>
        fifo_rden_o <= '0';
      when FIFO_ENABLE =>
        fifo_rden_o <= '1';
      when FIFO_READY =>
        fifo_rden_o <= '0';
    end case;
  end process fifo_read_output_decoder;


  fifo_read : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      fifo_dreg <= (others => '0');
      fifo_dreg_loaded <= '0';
    elsif rising_edge(clk) then
      if fifo_read_state = FIFO_READY then
        if fifo_dreg_loaded = '0' then
          fifo_dreg <= fifo_dout_i;
          fifo_dreg_loaded <= '1';
        end if;
      else
        fifo_dreg_loaded <= '0';
      end if;
    end if;
  end process fifo_read;


  rx_bytecnt_statemachine_decoder : process(rx_bytecnt_state, axi_lite_r_state,
                                            M_AXI_rdata, M_AXI_rvalid) is
  begin
    rx_bytecnt_state_nxt <= rx_bytecnt_state;

    if axi_lite_r_state = AXI_READ_DATA_BUFFER and M_AXI_rvalid = '1' then
      if rx_bytecnt_state = RX_B9 then
        rx_bytecnt_state_nxt <= RX_B0;
      else
        rx_bytecnt_state_nxt <= rx_bytecnt_state + 1;
      end if;
    end if;
  end process rx_bytecnt_statemachine_decoder;


  -- This process fills a temporary std_logic_vector with the received
  -- bytes and puts them together in the form of 2 addresses of 4 bytes
  -- wide (8 bytes in total).
  -- Each received byte is shifted n*8 bits to the left depending on the
  -- position of the byte. This way the end result after having received
  -- 8 bytes is:
  --  79-72  71-64  63-56  55-48  47-40  39-32  31-24  23-16  15-8  7-0
  --    B9     B8     B7     B6     B5     B4     B3     B2     B1   B0
  -- |-mon-||-flt-| |---------addr1---------|   |---------addr2--------|
  --
  -- The received bytes are left shifted to their correct position,
  -- master sends the MSB first.
  rcv_tmp_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      rcv_tmp <= (others => '0');
    elsif rising_edge(clk) then
      if axi_lite_r_state = AXI_READ_DATA_BUFFER and M_AXI_rvalid = '1' then
        -- Copy lowest rdata byte into right most byte of rcv_tmp
        rcv_tmp(rcv_tmp'low+7 downto rcv_tmp'low) <= M_AXI_rdata(7 downto 0);

        -- Left shift rcv_tmp 8 bits
        for i in rcv_tmp'high-8 downto rcv_tmp'low loop
          rcv_tmp(i+8) <= rcv_tmp(i);
        end loop;
      end if;
    end if;
  end process rcv_tmp_register;


  send_nibble_statemachine_decoder : process(send_nibble_state,
                                             axi_lite_w_state, M_AXI_bvalid) is
  begin
    send_nibble_state_nxt <= send_nibble_state;

    if axi_lite_w_state = AXI_WRITE_RESP and M_AXI_bvalid = '1' then
      if send_nibble_state = LF then
        send_nibble_state_nxt <= RWCH;
      else
        send_nibble_state_nxt <= send_nibble_state + 1;
      end if;
    end if;
  end process send_nibble_statemachine_decoder;


  axi_lite_r_statemachine_decoder : process(axi_lite_r_state, axi_lite_w_state,
                                            fifo_read_state, rx_bytecnt_state,
                                            M_AXI_rdata, M_AXI_rvalid) is
  begin
    axi_lite_r_state_nxt <= axi_lite_r_state;

    case axi_lite_r_state is
      when AXI_IDLE =>
        if axi_lite_w_state = AXI_IDLE and fifo_read_state = FIFO_IDLE then
          axi_lite_r_state_nxt <= AXI_READ_REQ_STATUS;
        end if;
      when AXI_READ_REQ_STATUS =>
        axi_lite_r_state_nxt <= AXI_READ_DATA_STATUS;
      when AXI_READ_REQ_BUFFER =>
        axi_lite_r_state_nxt <= AXI_READ_DATA_BUFFER;
      when AXI_READ_DATA_STATUS =>
        if M_AXI_rvalid = '1' then
          -- Check !rx_empty bit
          if M_AXI_rdata(0) = '1' then
            -- There is data available!
            axi_lite_r_state_nxt <= AXI_READ_REQ_BUFFER;
          else
            axi_lite_r_state_nxt <= AXI_IDLE;
          end if;
        end if;
      when AXI_READ_DATA_BUFFER =>
        if M_AXI_rvalid = '1' then
          if rx_bytecnt_state = RX_B9 then
            -- Now reading last byte, next state back to AXI_IDLE
            axi_lite_r_state_nxt <= AXI_IDLE;
          else
            axi_lite_r_state_nxt <= AXI_READ_REQ_STATUS;
          end if;
        end if;
      when others =>
        null;

    end case;
  end process axi_lite_r_statemachine_decoder;


  axi_lite_w_statemachine_decoder : process(axi_lite_w_state, axi_lite_r_state,
                                            fifo_read_state, send_nibble_state,
                                            M_AXI_rdata, M_AXI_rvalid,
                                            M_AXI_bvalid) is
  begin
    axi_lite_w_state_nxt <= axi_lite_w_state;

    case axi_lite_w_state is
      when AXI_IDLE =>
        if axi_lite_r_state = AXI_IDLE and fifo_read_state /= FIFO_IDLE then
          axi_lite_w_state_nxt <= AXI_READ_REQ_STATUS;
        end if;
      when AXI_READ_REQ_STATUS =>
        axi_lite_w_state_nxt <= AXI_READ_DATA_STATUS;
      when AXI_READ_DATA_STATUS =>
        if M_AXI_rvalid = '1' then
          if M_AXI_rdata(3) /= '1' then
            -- tx buffer is not full
            axi_lite_w_state_nxt <= AXI_WRITE_REQ_DATA;
          else
            -- tx buffer is full, back to reading status register again
            axi_lite_w_state_nxt <= AXI_READ_REQ_STATUS;
          end if;
        end if;
      when AXI_WRITE_REQ_DATA =>
        axi_lite_w_state_nxt <= AXI_WRITE_RESP;
      when AXI_WRITE_RESP =>
        if M_AXI_bvalid = '1' then
          if send_nibble_state = LF and fifo_read_state = FIFO_IDLE then
            axi_lite_w_state_nxt <= AXI_IDLE;
          else
            axi_lite_w_state_nxt <= AXI_READ_REQ_STATUS;
          end if;
        end if;
      when others =>
        null;

    end case;
  end process axi_lite_w_statemachine_decoder;


  --
  -- Process that controls the registers for the
  --   AXI Lite Write Request channel
  --
  axi_lite_write_req_channel : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      axi_awaddr <= (others => '0');
      axi_awvalid <= '0';
    elsif rising_edge(clk) then
      if axi_lite_w_state = AXI_WRITE_REQ_DATA then
        axi_awaddr <= AXI_WRITE_TXBUF_ADDR;
        axi_awvalid <= '1';
      elsif axi_lite_w_state = AXI_WRITE_RESP then
        if M_AXI_bvalid = '1' then
          axi_awaddr <= (others => '0');
          axi_awvalid <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_write_req_channel;

  --
  -- Process that controls the registers for the
  --   AXI Lite Write Data channel
  --
  axi_lite_write_data_channel : process(clk, rst_n) is
    variable ascii : std_logic_vector(7 downto 0);
  begin
    if rst_n = '0' then
      axi_wdata <= (others => '0');
      axi_wvalid <= '0';
      fifo_tmp <= (others => '0');
    elsif rising_edge(clk) then
      case axi_lite_w_state is
        when AXI_IDLE =>
          axi_wdata <= (others => '0');
          axi_wvalid <= '0';
        when AXI_READ_REQ_STATUS =>
          if send_nibble_state = RWCH then
            -- Only copy fifo_tmp once
            fifo_tmp <= fifo_dreg;
          end if;
        when AXI_WRITE_REQ_DATA =>
          case send_nibble_state is
            when RWCH =>
              if fifo_tmp(180) = rd_transaction then
                ascii := r_ascii;
              elsif fifo_tmp(180) = wr_transaction then
                ascii := w_ascii;
              else -- shouldn't happen
                ascii := u_ascii;
              end if;
            when NUL1 | NUL2 | NUL3 | NUL4 | NUL5 | NUL6 =>
              ascii := "00110000"; -- '0' (ASCII: 48)
            when HEX1 | HEX2 | HEX3 | HEX4 | HEX5 | HEX6 =>
              ascii := "01111000"; -- 'x' (ASCII: 120)
            when SP1 | SP2 | SP3 | SP4 | SP5 | SP6 =>
              ascii := "00100000"; -- ' ' (ASCII: 32)
            when CR   =>
              ascii := "00001101"; -- CR (ASCII: 13)
            when LF   =>
              ascii := "00001010"; -- LF (ASCII: 10)
            when others =>
              -- Convert the binary representation to hexademicals
              -- encoded in ASCII characters.
              ascii := convert_to_ascii(fifo_tmp(179 downto 176));
              -- Left-shift fifo_tmp 4 bits
              for k in fifo_tmp'high downto fifo_tmp'low+4 loop
                fifo_tmp(k) <= fifo_tmp(k - 4);
              end loop;
              fifo_tmp(3 downto 0) <= (others => '0');
          end case;
          axi_wdata(UART_DATA_WIDTH-1 downto 8) <= (others => '0');
          axi_wdata(7 downto 0) <= ascii;
          axi_wvalid <= '1';

        when AXI_WRITE_RESP =>
          if M_AXI_bvalid = '1' then
            axi_wdata <= (others => '0');
            axi_wvalid <= '0';
          end if;

        when others =>
          null;
      end case;
    end if;
  end process axi_lite_write_data_channel;

  --
  -- Process that controls the registers for the
  --   AXI Lite Write Response channel
  --
  axi_lite_write_resp_channel : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      axi_bready <= '0';
    elsif rising_edge(clk) then
      case axi_lite_w_state is
        when AXI_IDLE =>
          axi_bready <= '0';
        when AXI_WRITE_REQ_DATA =>
          axi_bready <= '1';
        when AXI_WRITE_RESP =>
          if M_AXI_bvalid = '1' then
            axi_bready <= '0';
          end if;
        when others =>
          null;
      end case;
    end if;
  end process axi_lite_write_resp_channel;

  --
  -- Process that controls the registers for the
  --   AXI Lite Read Request channel
  --
  axi_lite_read_req_channel : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      axi_araddr <= (others => '0');
      axi_arvalid <= '0';
    elsif rising_edge(clk) then
      -- Default
      if (axi_lite_r_state = AXI_READ_REQ_STATUS or
          axi_lite_w_state = AXI_READ_REQ_STATUS) then
        axi_araddr <= AXI_READ_STATUS_ADDR;
        axi_arvalid <= '1';
      elsif axi_lite_r_state = AXI_READ_REQ_BUFFER then
        axi_araddr <= AXI_READ_RXBUFFER_ADDR;
        axi_arvalid <= '1';
      elsif (axi_lite_r_state = AXI_READ_DATA_STATUS or
             axi_lite_w_state = AXI_READ_DATA_STATUS or
             axi_lite_r_state = AXI_READ_DATA_BUFFER) then
        if M_AXI_rvalid = '1' then
          axi_araddr <= (others => '0');
          axi_arvalid <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_read_req_channel;


  --
  -- Process that controls the registers for the
  --   AXI Lite Read Data channel
  --
  axi_lite_read_data_channel : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      axi_rready <= '0';
    elsif rising_edge(clk) then
      if (axi_lite_r_state = AXI_READ_REQ_STATUS or
          axi_lite_w_state = AXI_READ_REQ_STATUS) then
        axi_rready <= '0';
      elsif axi_lite_r_state = AXI_READ_REQ_BUFFER then
        axi_rready <= '0';
      elsif (axi_lite_r_state = AXI_READ_DATA_STATUS or
             axi_lite_w_state = AXI_READ_DATA_STATUS or
             axi_lite_r_state = AXI_READ_DATA_BUFFER) then
        if M_AXI_rvalid = '1' then
          axi_rready <= '1';
        end if;
      end if;
    end if;
  end process axi_lite_read_data_channel;


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


  rcv_reg_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      -- Default values for the address monitor
      rcv_reg((ADDR_WIDTH*2)-1+16 downto (ADDR_WIDTH*2)+8) <= mon_en_def;
      rcv_reg((ADDR_WIDTH*2)-1+8 downto (ADDR_WIDTH*2)) <= flt_en_def;
      rcv_reg((ADDR_WIDTH*2)-1 downto ADDR_WIDTH) <= addr1_def;
      rcv_reg(ADDR_WIDTH-1 downto 0) <= addr2_def;
      rcv_tmp_ready <= '0';
    elsif rising_edge(clk) then
      if axi_lite_r_state = AXI_READ_DATA_BUFFER and M_AXI_rvalid = '1' then
        if rx_bytecnt_state = RX_B9 then
          -- Delay copying rcv_tmp to rcv_reg with 1 clock cycle
          rcv_tmp_ready <= '1';
        end if;
      end if;

      if rcv_tmp_ready = '1' then
        rcv_reg <= rcv_tmp;
        rcv_tmp_ready <= '0';
      end if;
    end if;
  end process rcv_reg_register;


  -- The highest 8 bits of the rcv register represent the monitor enable,
  -- of which the lowest 2 bytes must be put on the output signal.
  --   79-72
  --     B9
  --  |--mon--|
  monitor_en_o <= rcv_reg((ADDR_WIDTH*2)-1+10 downto (ADDR_WIDTH*2)+8);

  -- The next 8 bits of the rcv register represent the address filter,
  -- of which the lowest bit must be put on the output signal.
  --   71-64
  --     B8
  --  |--flt--|
  addr_filter_o <= rcv_reg(ADDR_WIDTH*2);

  -- The high(-16) 32 bits of the rcv register represent the
  -- addr1 address (start function), the low 32 bits represent
  -- the addr2 address (end function).
  --   63-56  55-48  47-40  39-32  31-24  23-16  15-8  7-0
  --    B7     B6     B5     B4     B3     B2     B1    B0
  --   |---------addr1---------|   |---------addr2--------|
  addr1_monitor_o <= rcv_reg((ADDR_WIDTH*2)-1 downto ADDR_WIDTH);
  addr2_monitor_o <= rcv_reg(ADDR_WIDTH-1 downto 0);


  -- For debug purposes, put least significant bits on the LEDs
  axi_lite_state_led : process(axi_lite_w_state, axi_lite_r_state,
                               fifo_empty_i, rx_bytecnt_state) is
  begin
    if fifo_empty_i = '1' then
      leds(0) <= '1';
    else
      leds(0) <= '0';
    end if;

    if rx_bytecnt_state = "000" then
      leds(1) <= '1';
    else
      leds(1) <= '0';
    end if;

    case axi_lite_r_state is
      when AXI_IDLE =>
        leds(4 downto 2) <= (2 => '1', others => '0');
      when AXI_READ_DATA_STATUS =>
        leds(4 downto 2) <= (3 => '1', others => '0');
      when AXI_READ_DATA_BUFFER =>
        leds(4 downto 2) <= (4 => '1', others => '0');
      when others =>
        leds(4 downto 2) <= (others => '0');
    end case;

    case axi_lite_w_state is
      when AXI_IDLE =>
        leds(7 downto 5) <= (5 => '1', others => '0');
      when AXI_READ_REQ_STATUS =>
        leds(7 downto 5) <= (6 => '1', others => '0');
      when AXI_WRITE_REQ_DATA =>
        leds(7 downto 5) <= (7 => '1', others => '0');
      when others =>
        leds(7 downto 5) <= (others => '0');
    end case;

  end process axi_lite_state_led;

end architecture behaviour;
