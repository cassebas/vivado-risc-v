library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boot_device_datarcv is
  generic (BRAM_WEA_WIDTH  : integer := 4;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_DATA_WIDTH : integer := 32;
           UART_ADDR_WIDTH : integer := 16;
           UART_DATA_WIDTH : integer := 32;
           BRAM_SIZE       : integer := 2**10);

  port (clk           : in std_logic;
        rst_n         : in std_logic;

        -- This signal indicates the start of a new sequence of
        -- repetitions, where the two BlockRAMs are swapped. This
        -- means that this component should first send the
        -- "START" command to the host computer.
        -- The cpu_reset_n signal is active *low*
        logic_rst_n   : in std_logic;

        -- LEDs (debug)
        led_out : out std_logic_vector(7 downto 0);

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
        M_AXI_rready  : out std_logic;

        -- Filler address ports
        fill_wea_o  : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        fill_addr_o : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fill_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
end boot_device_datarcv;


architecture behavior of boot_device_datarcv is

  type axi_lite_state_type is (AXI_IDLE,
                               AXI_READ_REQ_STATUS,
                               AXI_READ_REQ_BUFFER,
                               AXI_READ_DATA_STATUS,
                               AXI_READ_DATA_BUFFER,
                               AXI_WRITE_REQ_DATA,
                               AXI_WRITE_RESP);
  signal axi_lite_r_state, axi_lite_r_state_nxt : axi_lite_state_type;
  signal axi_lite_w_state, axi_lite_w_state_nxt : axi_lite_state_type;

  signal rcv_reg : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal rcv_tmp : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal rcv_tmp_ready : std_logic;

  signal fill_wea  : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal fill_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal fill_addr_next : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal fill_data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal load_data : std_logic;
  signal next_addr : std_logic;

  constant MAX_ADDR : integer := BRAM_SIZE - 1;

  constant B0   : unsigned(1 downto 0) := "00";
  constant B1   : unsigned(1 downto 0) := "01";
  constant B2   : unsigned(1 downto 0) := "10";
  constant B3   : unsigned(1 downto 0) := "11";
  constant BFST : unsigned(1 downto 0) := B0;
  constant BLST : unsigned(1 downto 0) := B3;

  -- For counting the sent bytes we will need 2 bits, because a
  -- maximum of 4 bytes will be sent.
  -- The bytes received are:
  --  B0  -> first byte
  --  B3  -> last byte
  signal tx_bytecnt_state, tx_bytecnt_state_nxt : unsigned(1 downto 0);

  -- For counting the received bytes we will need 2 bits, because a
  -- maximum of 4 bytes will be received.
  -- The bytes received are:
  --  B0  -> first byte
  --  B3  -> last byte
  signal rx_bytecnt_state, rx_bytecnt_state_nxt : unsigned(1 downto 0);

  -- Some named constants for the fixed command to be sent
  constant CMD_B0 : std_logic_vector(7 downto 0) := "00110101"; -- '5' (ASCII: 53)
  constant CMD_B1 : std_logic_vector(7 downto 0) := "00101010"; -- '*' (ASCII: 42)
  constant CMD_B2 : std_logic_vector(7 downto 0) := "00110100"; -- '4' (ASCII: 52)
  constant CMD_B3 : std_logic_vector(7 downto 0) := "00110010"; -- '2' (ASCII: 50)

  --
  -- AXI Lite signals
  --
  -- AXI Lite Write Request channel
  signal axi_awaddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_awvalid : std_logic;
  signal axi_awready : std_logic;
  -- AXI Lite Write Data channel
  signal axi_wdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  signal axi_wvalid  : std_logic;
  signal axi_wready  : std_logic;
  -- AXI Lite Write Response channel
  signal axi_bvalid  : std_logic;
  signal axi_bready  : std_logic;
  -- AXI Lite Read Request channel
  signal axi_araddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_arvalid : std_logic;
  signal axi_arready : std_logic;
  -- AXI Lite Read Data channel
  signal axi_rdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  signal axi_rvalid  : std_logic;
  signal axi_rready  : std_logic;


  -- Read from UART rx buffer: address is 4'h00
  constant AXI_READ_RXBUF_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (others => '0');
  -- Write to UART tx buffer: address is 4'h04
  constant AXI_WRITE_TXBUF_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (2 => '1', others => '0');
  -- Read from UART status register: address is 4'h08
  constant AXI_READ_STATUS_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', others => '0');
  -- Write to UART control register: address is 4'h0c
  constant AXI_WRITE_CTRL_ADDR : std_logic_vector(UART_ADDR_WIDTH-1 downto 0) :=
    (3 => '1', 2 => '1', others => '0');

  signal snd_data_active : std_logic;

begin
  statemachine_register : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        rx_bytecnt_state <= BFST;
        tx_bytecnt_state <= BFST;
        axi_lite_r_state <= AXI_IDLE;
        axi_lite_w_state <= AXI_IDLE;
      else
        rx_bytecnt_state <= rx_bytecnt_state_nxt;
        tx_bytecnt_state <= tx_bytecnt_state_nxt;
        axi_lite_r_state <= axi_lite_r_state_nxt;
        axi_lite_w_state <= axi_lite_w_state_nxt;
      end if;
    end if;
  end process statemachine_register;


  rx_bytecnt_statemachine_decoder : process(rx_bytecnt_state, axi_lite_r_state,
                                            axi_rvalid) is
  begin
    rx_bytecnt_state_nxt <= rx_bytecnt_state;

    if axi_lite_r_state = AXI_READ_DATA_BUFFER and axi_rvalid = '1' then
      if rx_bytecnt_state = BLST then
        rx_bytecnt_state_nxt <= BFST;
      else
        rx_bytecnt_state_nxt <= rx_bytecnt_state + 1;
      end if;
    end if;
  end process rx_bytecnt_statemachine_decoder;


  tx_bytecnt_statemachine_decoder : process(tx_bytecnt_state, axi_lite_w_state,
                                            axi_bvalid) is
  begin
    tx_bytecnt_state_nxt <= tx_bytecnt_state;

    if axi_lite_w_state = AXI_WRITE_RESP and axi_bvalid = '1' then
      if tx_bytecnt_state = BLST then
        tx_bytecnt_state_nxt <= BFST;
      else
        tx_bytecnt_state_nxt <= tx_bytecnt_state + 1;
      end if;
    end if;
  end process tx_bytecnt_statemachine_decoder;


  axi_lite_r_statemachine_decoder : process(axi_lite_r_state, axi_lite_w_state,
                                            rx_bytecnt_state, snd_data_active,
                                            axi_rdata, axi_rvalid, axi_arready) is
  begin
    axi_lite_r_state_nxt <= axi_lite_r_state;

    case axi_lite_r_state is
      when AXI_IDLE =>
        if axi_lite_w_state = AXI_IDLE and snd_data_active /= '1' then
          axi_lite_r_state_nxt <= AXI_READ_REQ_STATUS;
        end if;
      when AXI_READ_REQ_STATUS =>
        if axi_arready = '1' then
          axi_lite_r_state_nxt <= AXI_READ_DATA_STATUS;
        end if;
      when AXI_READ_REQ_BUFFER =>
        if axi_arready = '1' then
          axi_lite_r_state_nxt <= AXI_READ_DATA_BUFFER;
        end if;
      when AXI_READ_DATA_STATUS =>
        if axi_rvalid = '1' then
          -- Check !rx_empty bit
          if axi_rdata(0) = '1' then
            -- There is data available!
            axi_lite_r_state_nxt <= AXI_READ_REQ_BUFFER;
          else
            axi_lite_r_state_nxt <= AXI_IDLE;
          end if;
        end if;
      when AXI_READ_DATA_BUFFER =>
        if axi_rvalid = '1' then
          if rx_bytecnt_state = BLST then
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
                                            snd_data_active, tx_bytecnt_state,
                                            axi_arready, axi_awready,
                                            axi_rdata, axi_rvalid,
                                            axi_wready, axi_bvalid) is
  begin
    axi_lite_w_state_nxt <= axi_lite_w_state;

    case axi_lite_w_state is
      when AXI_IDLE =>
        if axi_lite_r_state = AXI_IDLE and snd_data_active = '1' then
          axi_lite_w_state_nxt <= AXI_READ_REQ_STATUS;
        end if;
      when AXI_READ_REQ_STATUS =>
        if axi_arready = '1' then
          axi_lite_w_state_nxt <= AXI_READ_DATA_STATUS;
        end if;
      when AXI_READ_DATA_STATUS =>
        if axi_rvalid = '1' then
          if axi_rdata(3) /= '1' then
            -- tx buffer is not full
            axi_lite_w_state_nxt <= AXI_WRITE_REQ_DATA;
          else
            -- tx buffer is full, back to reading status register again
            axi_lite_w_state_nxt <= AXI_READ_REQ_STATUS;
          end if;
        end if;
      when AXI_WRITE_REQ_DATA =>
        if axi_awready = '1' and axi_wready = '1' then
          axi_lite_w_state_nxt <= AXI_WRITE_RESP;
        end if;
      when AXI_WRITE_RESP =>
        if axi_bvalid = '1' then
          if tx_bytecnt_state = BLST then
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
  axi_lite_write_req_channel : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        axi_awaddr <= (others => '0');
        axi_awvalid <= '0';
        axi_awready <= '0';
      else
        if axi_lite_w_state = AXI_WRITE_REQ_DATA then
          axi_awaddr <= AXI_WRITE_TXBUF_ADDR;
          axi_awvalid <= '1';

          if M_AXI_awready = '1' then
            axi_awready <= '1';
          end if;
        else
          axi_awaddr <= (others => '0');
          axi_awvalid <= '0';
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_write_req_channel;


  --
  -- Process that controls the registers for the
  --   AXI Lite Write Data channel
  --
  axi_lite_write_data_channel : process(clk) is
    variable ascii : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        axi_wdata <= (others => '0');
        axi_wvalid <= '0';
        axi_wready <= '0';
      else
        if axi_lite_w_state = AXI_WRITE_REQ_DATA then
          case tx_bytecnt_state is
            when B0     => ascii := CMD_B0;
            when B1     => ascii := CMD_B1;
            when B2     => ascii := CMD_B2;
            when others => ascii := CMD_B3;
          end case;
          axi_wdata(UART_DATA_WIDTH-1 downto 8) <= (others => '0');
          axi_wdata(7 downto 0) <= ascii;
          axi_wvalid <= '1';

          if M_AXI_wready = '1' then
            axi_wready <= '1';
          end if;
        else
          axi_wdata <= (others => '0');
          axi_wvalid <= '0';
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_write_data_channel;


  --
  -- Process that controls the registers for the
  --   AXI Lite Write Response channel
  --
  axi_lite_write_resp_channel : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        axi_bvalid <= '0';
        axi_bready <= '0';
      else
        if axi_lite_w_state = AXI_WRITE_RESP then
          if M_AXI_bvalid = '1' then
            axi_bvalid <= '1';
            axi_bready <= '1';
          end if;
        else
          axi_bvalid <= '0';
          axi_bready <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_write_resp_channel;


  --
  -- Process that controls the registers for the
  --   AXI Lite Read Request channel
  --
  axi_lite_read_req_channel : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        axi_araddr <= (others => '0');
        axi_arvalid <= '0';
        axi_arready <= '0';
      else
        if (axi_lite_w_state = AXI_READ_REQ_STATUS or
            axi_lite_r_state = AXI_READ_REQ_STATUS or
            axi_lite_r_state = AXI_READ_REQ_BUFFER) then

          if (axi_lite_w_state = AXI_READ_REQ_STATUS or
              axi_lite_r_state = AXI_READ_REQ_STATUS) then

            axi_araddr <= AXI_READ_STATUS_ADDR;
          else
            axi_araddr <= AXI_READ_RXBUF_ADDR;
          end if;

          axi_arvalid <= '1';

          if M_AXI_arready = '1' then
            axi_arready <= '1';
          end if;
        else
          axi_araddr <= (others => '0');
          axi_arvalid <= '0';
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_read_req_channel;

  --
  -- Process that controls the registers for the
  --   AXI Lite Read Data channel
  --
  axi_lite_read_data_channel : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        axi_rdata <= (others => '0');
        axi_rvalid <= '0';
        axi_rready <= '0';
      else
        if (axi_lite_w_state = AXI_READ_DATA_STATUS or
            axi_lite_r_state = AXI_READ_DATA_STATUS or
            axi_lite_r_state = AXI_READ_DATA_BUFFER) then

          if M_AXI_rvalid = '1' then
            axi_rdata <= M_AXI_rdata;
            axi_rvalid <= M_AXI_rvalid;
            axi_rready <= '1';
          end if;
        else
          axi_rdata <= (others => '0');
          axi_rvalid <= '0';
          axi_rready <= '0';
        end if;
      end if;
    end if;
  end process axi_lite_read_data_channel;



  -- This process fills a temporary std_logic_vector with the received
  -- bytes and puts them together in the form of 4 bytes.
  --
  -- Each received byte is shifted n*8 bits to the left depending on the
  -- position of the byte. This way the end result after having received
  -- 4 bytes is:
  --  31-24  23-16  15-8  7-0
  --    B3     B2     B1   B0
  -- |---------data-----------|
  --
  -- The received bytes are left shifted to their correct position,
  -- master sends the MSB first.
  rcv_tmp_register : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        rcv_tmp <= (others => '0');
      else
        if axi_lite_r_state = AXI_READ_DATA_BUFFER and axi_rvalid = '1' then
          -- Copy lowest rdata byte into right most byte of rcv_tmp
          rcv_tmp(rcv_tmp'low+7 downto rcv_tmp'low) <= axi_rdata(7 downto 0);

          -- Left shift rcv_tmp 8 bits
          for i in rcv_tmp'high-8 downto rcv_tmp'low loop
            rcv_tmp(i+8) <= rcv_tmp(i);
          end loop;
        end if;
      end if;
    end if;
  end process rcv_tmp_register;


  rcv_reg_register : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        rcv_reg <= (others => '0');
        rcv_tmp_ready <= '0';
      else
        if axi_lite_r_state = AXI_READ_DATA_BUFFER and axi_rvalid = '1' then
          if rx_bytecnt_state = BLST then
            -- Delay copying rcv_tmp to rcv_reg with 1 clock cycle
            rcv_tmp_ready <= '1';
          end if;
        end if;

        if rcv_tmp_ready = '1' then
          rcv_reg <= rcv_tmp;
          rcv_tmp_ready <= '0';
        end if;
      end if;
    end if;
  end process rcv_reg_register;


  fill_data_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        fill_wea <= (others => '0');
        fill_addr <= (others => '0');
        fill_data <= (others => '0');
        load_data <= '0';
        next_addr <= '0';
      else
        if rcv_tmp_ready = '1' then
          load_data <= '1';
        elsif load_data = '1' then
          fill_wea <= (others => '1');
          fill_data <= rcv_reg;
          load_data <= '0';
          next_addr <= '1';
        elsif next_addr = '1' then
          fill_wea <= (others => '0');
          fill_addr <= fill_addr_next;
          next_addr <= '0';
        end if;
      end if;
    end if;
  end process fill_data_proc;


  compute_next_address : process(fill_addr) is
    variable this_address : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  begin
    this_address := unsigned(fill_addr);
    if this_address >= MAX_ADDR then
      fill_addr_next <= (others => '0');
    else
      fill_addr_next <= std_logic_vector(this_address + 1);
    end if;
  end process compute_next_address;


  snd_data_proc : process(clk) is
  begin
    if rising_edge(clk) then
      if logic_rst_n = '0' then
        snd_data_active <= '1';
      else
        if snd_data_active = '1' then
          if axi_lite_w_state = AXI_WRITE_RESP and axi_bvalid = '1' then
            if tx_bytecnt_state = BLST then
              snd_data_active <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process snd_data_proc;


  --
  -- AXI Lite outputs connected to registers
  --
  -- AXI Lite Write Request channel
  M_AXI_awaddr  <= axi_awaddr;
  M_AXI_awvalid <= axi_awvalid;
  -- AXI Lite Write Data channel
  M_AXI_wdata   <= axi_wdata;
  M_AXI_wvalid  <= axi_wvalid;
  -- AXI Lite Write Response channel
  M_AXI_bready  <= axi_bready;
  -- AXI Lite Read Request channel
  M_AXI_araddr  <= axi_araddr;
  M_AXI_arvalid <= axi_arvalid;
  -- AXI Lite Read Data channel
  M_AXI_rready  <= axi_rready;


  --
  -- Block RAM output signals connected to registers
  --
  fill_wea_o  <= fill_wea;
  fill_addr_o <= fill_addr;
  fill_data_o <= fill_data;


  axi_lite_state_led : process(axi_lite_w_state, axi_lite_r_state,
                               tx_bytecnt_state, rx_bytecnt_state,
                               snd_data_active) is
  begin
    if snd_data_active = '1' then
      led_out(0) <= '1';

      if tx_bytecnt_state /= "00" then
        led_out(1) <= '1';
      else
        led_out(1) <= '0';
      end if;

      case axi_lite_w_state is
        when AXI_IDLE =>
          led_out(7 downto 2) <= (2 => '1', others => '0');
        when AXI_READ_REQ_STATUS =>
          led_out(7 downto 2) <= (3 => '1', others => '0');
        when AXI_READ_DATA_STATUS =>
          led_out(7 downto 2) <= (4 => '1', others => '0');
        when AXI_WRITE_REQ_DATA =>
          led_out(7 downto 2) <= (5 => '1', others => '0');
        when AXI_WRITE_RESP =>
          led_out(7 downto 2) <= (6 => '1', others => '0');
        when others =>
          led_out(7 downto 2) <= (others => '0');
      end case;
    else
      led_out(0) <= '0';

      if rx_bytecnt_state /= "00" then
        led_out(1) <= '1';
      else
        led_out(1) <= '0';
      end if;

      case axi_lite_r_state is
        when AXI_IDLE =>
          led_out(7 downto 2) <= (2 => '1', others => '0');
        when AXI_READ_REQ_STATUS =>
          led_out(7 downto 2) <= (3 => '1', others => '0');
        when AXI_READ_REQ_BUFFER =>
          led_out(7 downto 2) <= (4 => '1', others => '0');
        when AXI_READ_DATA_STATUS =>
          led_out(7 downto 2) <= (5 => '1', others => '0');
        when AXI_READ_DATA_BUFFER =>
          led_out(7 downto 2) <= (6 => '1', others => '0');
        when others =>
          led_out(7 downto 2) <= (others => '0');
      end case;
    end if;

  end process axi_lite_state_led;


end architecture behavior;
