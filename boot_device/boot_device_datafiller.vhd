library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_datafiller is
  generic (BRAM_WEA_WIDTH  : integer := 4;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_DATA_WIDTH : integer := 32;
           UART_ADDR_WIDTH : integer := 16;
           UART_DATA_WIDTH : integer := 32);

  port (clk         : in std_logic;
        rst_n       : in std_logic;
        cpu_reset   : in std_logic;
        led_out     : out std_logic_vector(7 downto 0);
        uart_rx     : in std_logic;
        uart_tx     : out std_logic;
        uart_ctsn   : in std_logic;
        uart_rtsn   : out std_logic;
        interrupt   : out std_logic;
        fill_wea_o  : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        fill_addr_o : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fill_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
end entity boot_device_datafiller;


architecture structural of boot_device_datafiller is

  component uart is
    port (async_resetn  : in std_logic;
          clock         : in std_logic;
          s_axi_awaddr  : in std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
          s_axi_awvalid : in std_logic;
          s_axi_awready : out std_logic;
          s_axi_wdata   : out std_logic_vector(UART_DATA_WIDTH-1 downto 0);
          s_axi_wvalid  : in std_logic;
          s_axi_wready  : out std_logic;
          s_axi_bresp   : out std_logic_vector(1 downto 0);
          s_axi_bvalid  : out std_logic;
          s_axi_bready  : in std_logic;
          s_axi_araddr  : in std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
          s_axi_arvalid : in std_logic;
          s_axi_arready : out std_logic;
          s_axi_rdata   : out std_logic_vector(UART_DATA_WIDTH-1 downto 0);
          s_axi_rresp   : out std_logic_vector(1 downto 0);
          s_axi_rvalid  : out std_logic;
          s_axi_rready  : in std_logic;

          -- Interrupts
          interrupt     : out std_logic;

          -- RS232
          TxD           : out std_logic;
          RxD           : in std_logic;
          RTSn          : out std_logic;
          CTSn          : in std_logic);
    end component uart;

  component boot_device_datarcv is
    port (clk           : in std_logic;
          rst_n         : in std_logic;

          -- This signal indicates the start of a new sequence of
          -- repetitions, where the two BlockRAMs are swapped. This
          -- means that this component should first send the
          -- "START" command to the host computer.
          cpu_reset     : in std_logic;

          -- LEDs (debug)
          led_out       : out std_logic_vector(7 downto 0);

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
  end component boot_device_datarcv;

  signal axi_awaddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_awvalid : std_logic;
  signal axi_awready : std_logic;
  signal axi_wdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  signal axi_wvalid  : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp   : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_bready  : std_logic;
  signal axi_araddr  : std_logic_vector(UART_ADDR_WIDTH-1 downto 0);
  signal axi_arvalid : std_logic;
  signal axi_arready : std_logic;
  signal axi_rdata   : std_logic_vector(UART_DATA_WIDTH-1 downto 0);
  signal axi_rresp   : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;
  signal axi_rready  : std_logic;

begin

  uart_0 : uart
    port map (async_resetn  => rst_n,
              clock         => clk,
              s_axi_awaddr  => axi_awaddr,
              s_axi_awvalid => axi_awvalid,
              s_axi_awready => axi_awready,
              s_axi_wdata   => axi_wdata,
              s_axi_wvalid  => axi_wvalid,
              s_axi_wready  => axi_wready,
              s_axi_bresp   => axi_bresp,
              s_axi_bvalid  => axi_bvalid,
              s_axi_bready  => axi_bready,
              s_axi_araddr  => axi_araddr,
              s_axi_arvalid => axi_arvalid,
              s_axi_arready => axi_arready,
              s_axi_rdata   => axi_rdata,
              s_axi_rresp   => axi_rresp,
              s_axi_rvalid  => axi_rvalid,
              s_axi_rready  => axi_rready,
              interrupt     => interrupt,
              TxD           => uart_tx,
              RxD           => uart_rx,
              RTSn          => uart_rtsn,
              CTSn          => uart_ctsn);

  boot_device_datarcv_0 : boot_device_datarcv
    port map (clk           => clk,
              rst_n         => rst_n,
              cpu_reset     => cpu_reset,
              led_out       => led_out,
              M_AXI_awaddr  => axi_awaddr,
              M_AXI_awvalid => axi_awvalid,
              M_AXI_awready => axi_awready,
              M_AXI_wdata   => axi_wdata,
              M_AXI_wvalid  => axi_wvalid,
              M_AXI_wready  => axi_wready,
              M_AXI_bresp   => axi_bresp,
              M_AXI_bvalid  => axi_bvalid,
              M_AXI_bready  => axi_bready,
              M_AXI_araddr  => axi_araddr,
              M_AXI_arvalid => axi_arvalid,
              M_AXI_arready => axi_arready,
              M_AXI_rdata   => axi_rdata,
              M_AXI_rresp   => axi_rresp,
              M_AXI_rvalid  => axi_rvalid,
              M_AXI_rready  => axi_rready,
              fill_wea_o    => fill_wea_o,
              fill_addr_o   => fill_addr_o,
              fill_data_o   => fill_data_o);

end architecture;
