library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device is
  generic (S_AXI_DATA_WIDTH : integer   := 32;
           S_AXI_ADDR_WIDTH : integer   := 16;
           BRAM_DATA_WIDTH  : integer   := 32;
           BRAM_ADDR_WIDTH  : integer   := 14);

  port (S00_AXI_aclk    : in std_logic;  --  AXI clock
        S00_AXI_aresetn : in std_logic;  --  AXI reset, active low

        -- -----------------------------
        --  Write request channel
        -- -----------------------------
        -- S00_AXI_awid    : in std_logic_vector(3 downto 0);
        S00_AXI_awaddr  : in std_logic_vector(S_AXI_ADDR_WIDTH-1 downto 0);
        -- S00_AXI_awlen   : in std_logic_vector(7 downto 0);
        -- S00_AXI_awsize  : in std_logic_vector(2 downto 0);
        -- S00_AXI_awburst : in std_logic_vector(1 downto 0);
        -- S00_AXI_awlock  : in std_logic_vector(0 downto 0);
        -- S00_AXI_awcache : in std_logic_vector(3 downto 0);
        S00_AXI_awprot  : in std_logic_vector(2 downto 0);
        S00_AXI_awqos   : in std_logic_vector(3 downto 0);
        -- Handshake
        S00_AXI_awvalid : in std_logic;
        S00_AXI_awready : out std_logic;

        -- -----------------------------
        --  Write data channel
        -- -----------------------------
        S00_AXI_wdata   : in std_logic_vector(S_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_wstrb   : in std_logic_vector((S_AXI_DATA_WIDTH/8)-1 downto 0);
        S00_AXI_wlast   : in std_logic;
        -- Handshake
        S00_AXI_wvalid  : in std_logic;
        S00_AXI_wready  : out std_logic;

        -- -----------------------------
        --  Write response channel
        -- -----------------------------
        S00_AXI_bid     : out std_logic_vector(3 downto 0);
        S00_AXI_bresp   : out std_logic_vector(1 downto 0);
        -- Handshake
        S00_AXI_bvalid  : out std_logic;
        S00_AXI_bready  : in std_logic;

        -- -----------------------------
        -- Read request channel
        -- -----------------------------
        S00_AXI_arid    : in std_logic_vector(3 downto 0);
        S00_AXI_araddr  : in std_logic_vector(S_AXI_ADDR_WIDTH-1 downto 0);
        S00_AXI_arlen   : in std_logic_vector(7 downto 0);
        S00_AXI_arsize  : in std_logic_vector(2 downto 0);
        S00_AXI_arburst : in std_logic_vector(1 downto 0);
        S00_AXI_arlock  : in std_logic_vector(0 downto 0);
        S00_AXI_arcache : in std_logic_vector(3 downto 0);
        S00_AXI_arprot  : in std_logic_vector(2 downto 0);
        S00_AXI_arqos   : in std_logic_vector(3 downto 0);
        -- Handshake
        S00_AXI_arvalid : in std_logic;
        S00_AXI_arready : out std_logic;

        -- -----------------------------
        -- Read data channel
        -- -----------------------------
        S00_AXI_rid     : out std_logic_vector(3 downto 0);
        S00_AXI_rdata   : out std_logic_vector(S_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_rresp   : out std_logic_vector(1 downto 0);
        S00_AXI_rlast   : out std_logic;
        -- Handshake
        S00_AXI_rvalid  : out std_logic;
        S00_AXI_rready  : in std_logic);
end boot_device;


architecture behavior of boot_device is

  signal bram_addr   : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal bram_data_i : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal bram_data_o : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal bram_wea    : std_logic_vector(3 downto 0);

  -- Component declarations
  component boot_device_bootcode is
    generic (BRAM_DATA_WIDTH : integer := 32;
             BRAM_ADDR_WIDTH : integer := 14);

    port (clka  : in std_logic;
          wea   : in std_logic_vector(3 downto 0);
          addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component boot_device_bootcode;

  component boot_device_axislave is
    generic (C_S_AXI_DATA_WIDTH  : integer   := 32;
             C_S_AXI_ADDR_WIDTH  : integer   := BRAM_ADDR_WIDTH);
    port (bram_addr_o : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          bram_data_i : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          bram_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          bram_wea_o  : out std_logic_vector(3 downto 0);

          S_AXI_aclk    : in std_logic;
          S_AXI_aresetn : in std_logic;
          S_AXI_awaddr  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
          S_AXI_awprot  : in std_logic_vector(2 downto 0);
          S_AXI_awvalid : in std_logic;
          S_AXI_awready : out std_logic;
          S_AXI_wdata   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
          S_AXI_wstrb   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
          S_AXI_wvalid  : in std_logic;
          S_AXI_wready  : out std_logic;
          S_AXI_bresp   : out std_logic_vector(1 downto 0);
          S_AXI_bvalid  : out std_logic;
          S_AXI_bready  : in std_logic;
          S_AXI_araddr  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
          S_AXI_arprot  : in std_logic_vector(2 downto 0);
          S_AXI_arvalid : in std_logic;
          S_AXI_arready : out std_logic;
          S_AXI_rdata   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
          S_AXI_rresp   : out std_logic_vector(1 downto 0);
          S_AXI_rvalid  : out std_logic;
          S_AXI_rready  : in std_logic);
  end component boot_device_axislave;

  constant LSB_ADDR_BIT  : integer := (S_AXI_DATA_WIDTH/32) + 1;

begin

  boot_device_bootcode_inst : boot_device_bootcode
    port map (clka => s00_axi_aclk,
              wea  => bram_wea,
              addra => bram_addr,
              dina => bram_data_i,
              douta => bram_data_o);

  boot_device_axislave_inst : boot_device_axislave
    generic map (
      C_S_AXI_DATA_WIDTH => S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH => BRAM_ADDR_WIDTH)
    port map (
      bram_addr_o => bram_addr,
      bram_data_i => bram_data_o,
      bram_data_o => bram_data_i,
      bram_wea_o  => bram_wea,

      S_AXI_aclk    => s00_axi_aclk,
      S_AXI_aresetn => s00_axi_aresetn,
      S_AXI_awaddr  => s00_axi_awaddr(S_AXI_ADDR_WIDTH-1 downto LSB_ADDR_BIT),
      S_AXI_awprot  => s00_axi_awprot,
      S_AXI_awvalid => s00_axi_awvalid,
      S_AXI_awready => s00_axi_awready,
      S_AXI_wdata   => s00_axi_wdata,
      S_AXI_wstrb   => s00_axi_wstrb,
      S_AXI_wvalid  => s00_axi_wvalid,
      S_AXI_wready  => s00_axi_wready,
      S_AXI_bresp   => s00_axi_bresp,
      S_AXI_bvalid  => s00_axi_bvalid,
      S_AXI_bready  => s00_axi_bready,
      S_AXI_araddr  => s00_axi_araddr(S_AXI_ADDR_WIDTH-1 downto LSB_ADDR_BIT),
      S_AXI_arprot  => s00_axi_arprot,
      S_AXI_arvalid => s00_axi_arvalid,
      S_AXI_arready => s00_axi_arready,
      S_AXI_rdata   => s00_axi_rdata,
      S_AXI_rresp   => s00_axi_rresp,
      S_AXI_rvalid  => s00_axi_rvalid,
      S_AXI_rready  => s00_axi_rready);

end architecture behavior;
