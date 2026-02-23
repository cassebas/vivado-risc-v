library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boot_device_datarcv is
  generic (BRAM_WEA_WIDTH  : integer := 4;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_DATA_WIDTH : integer := 32;
           UART_ADDR_WIDTH : integer := 16;
           UART_DATA_WIDTH : integer := 32);
  port (clk   : in std_logic;
        rst_n : in std_logic;

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

  signal rcv_reg : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal rcv_tmp : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal rcv_tmp_ready : std_logic;

  -- For counting the received bytes we will need 2 bits, because a
  -- maximum of 4 bytes will be received.
  -- The bytes received are:
  --  B0  -> first byte
  --  B3  -> last byte
  signal rx_bytecnt_state, rx_bytecnt_state_nxt : unsigned(1 downto 0);
  constant RX_B0 : unsigned(1 downto 0) := "00";
  constant RX_B3 : unsigned(1 downto 0) := "11";
  constant RX_BFST : unsigned(1 downto 0) := RX_B0;
  constant RX_BLST : unsigned(1 downto 0) := RX_B3;


begin
  statemachine_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      rx_bytecnt_state <= RX_BFST;
      axi_lite_r_state <= AXI_IDLE;
      axi_lite_w_state <= AXI_IDLE;
    elsif rising_edge(clk) then
      rx_bytecnt_state <= rx_bytecnt_state_nxt;
      axi_lite_r_state <= axi_lite_r_state_nxt;
      axi_lite_w_state <= axi_lite_w_state_nxt;
    end if;
  end process statemachine_register;


  rx_bytecnt_statemachine_decoder : process(rx_bytecnt_state, axi_lite_r_state,
                                            M_AXI_rdata, M_AXI_rvalid) is
  begin
    rx_bytecnt_state_nxt <= rx_bytecnt_state;

    if axi_lite_r_state = AXI_READ_DATA_BUFFER and M_AXI_rvalid = '1' then
      if rx_bytecnt_state = RX_BLST then
        rx_bytecnt_state_nxt <= RX_BFST;
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
  -- 4 bytes is:
  --  31-24  23-16  15-8  7-0
  --    B3     B2     B1   B0
  -- |---------data---------|
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


  rcv_reg_register : process(clk, rst_n) is
  begin
    if rst_n = '0' then
      rcv_reg <= (others => '0');
      rcv_tmp_ready <= '0';
    elsif rising_edge(clk) then
      if axi_lite_r_state = AXI_READ_DATA_BUFFER and M_AXI_rvalid = '1' then
        if rx_bytecnt_state = RX_BLST then
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


end architecture behavior;
