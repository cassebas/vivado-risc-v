library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4_passthrough is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 64);
  port (
    aclk            : in std_logic;
    aresetn         : in std_logic;
    S00_AXI_awid    : in std_logic_vector(3 downto 0);
    S00_AXI_awaddr  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    S00_AXI_awlen   : in std_logic_vector(7 downto 0);
    S00_AXI_awsize  : in std_logic_vector(2 downto 0);
    S00_AXI_awburst : in std_logic_vector(1 downto 0);
    S00_AXI_awlock  : in std_logic_vector(0 downto 0);
    S00_AXI_awcache : in std_logic_vector(3 downto 0);
    S00_AXI_awprot  : in std_logic_vector(2 downto 0);
    S00_AXI_awqos   : in std_logic_vector(3 downto 0);
    S00_AXI_awvalid : in std_logic;
    S00_AXI_awready : out std_logic;
    S00_AXI_wdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    S00_AXI_wstrb   : in std_logic_vector(7 downto 0);
    S00_AXI_wlast   : in std_logic;
    S00_AXI_wvalid  : in std_logic;
    S00_AXI_wready  : out std_logic;
    S00_AXI_bid     : out std_logic_vector(3 downto 0);
    S00_AXI_bresp   : out std_logic_vector(1 downto 0);
    S00_AXI_bvalid  : out std_logic;
    S00_AXI_bready  : in std_logic;
    S00_AXI_arid    : in std_logic_vector(3 downto 0);
    S00_AXI_araddr  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    S00_AXI_arlen   : in std_logic_vector(7 downto 0);
    S00_AXI_arsize  : in std_logic_vector(2 downto 0);
    S00_AXI_arburst : in std_logic_vector(1 downto 0);
    S00_AXI_arlock  : in std_logic_vector(0 downto 0);
    S00_AXI_arcache : in std_logic_vector(3 downto 0);
    S00_AXI_arprot  : in std_logic_vector(2 downto 0);
    S00_AXI_arqos   : in std_logic_vector(3 downto 0);
    S00_AXI_arvalid : in std_logic;
    S00_AXI_arready : out std_logic;
    S00_AXI_rid     : out std_logic_vector(3 downto 0);
    S00_AXI_rdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    S00_AXI_rresp   : out std_logic_vector(1 downto 0);
    S00_AXI_rlast   : out std_logic;
    S00_AXI_rvalid  : out std_logic;
    S00_AXI_rready  : in std_logic;

    M00_AXI_awid    : out std_logic_vector(3 downto 0);
    M00_AXI_awaddr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M00_AXI_awlen   : out std_logic_vector(7 downto 0);
    M00_AXI_awsize  : out std_logic_vector(2 downto 0);
    M00_AXI_awburst : out std_logic_vector(1 downto 0);
    M00_AXI_awlock  : out std_logic_vector(0 downto 0);
    M00_AXI_awcache : out std_logic_vector(3 downto 0);
    M00_AXI_awprot  : out std_logic_vector(2 downto 0);
    M00_AXI_awqos   : out std_logic_vector(3 downto 0);
    M00_AXI_awvalid : out std_logic;
    M00_AXI_awready : in std_logic;
    M00_AXI_wdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    M00_AXI_wstrb   : out std_logic_vector(7 downto 0);
    M00_AXI_wlast   : out std_logic;
    M00_AXI_wvalid  : out std_logic;
    M00_AXI_bid     : in std_logic_vector(3 downto 0);
    M00_AXI_wready  : in std_logic;
    M00_AXI_bresp   : in std_logic_vector(1 downto 0);
    M00_AXI_bvalid  : in std_logic;
    M00_AXI_bready  : out std_logic;
    M00_AXI_arid    : out std_logic_vector(3 downto 0);
    M00_AXI_araddr  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M00_AXI_arlen   : out std_logic_vector(7 downto 0);
    M00_AXI_arsize  : out std_logic_vector(2 downto 0);
    M00_AXI_arburst : out std_logic_vector(1 downto 0);
    M00_AXI_arlock  : out std_logic_vector(0 downto 0);
    M00_AXI_arcache : out std_logic_vector(3 downto 0);
    M00_AXI_arprot  : out std_logic_vector(2 downto 0);
    M00_AXI_arqos   : out std_logic_vector(3 downto 0);
    M00_AXI_arvalid : out std_logic;
    M00_AXI_arready : in std_logic;
    M00_AXI_rid     : in std_logic_vector(3 downto 0);
    M00_AXI_rdata   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    M00_AXI_rresp   : in std_logic_vector(1 downto 0);
    M00_AXI_rlast   : in std_logic;
    M00_AXI_rvalid  : in std_logic;
    M00_AXI_rready  : out std_logic);
end axi4_passthrough;

architecture behaviour of axi4_passthrough is

  signal awid    : std_logic_vector(3 downto 0);
  signal awaddr  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal awlen   : std_logic_vector(7 downto 0);
  signal awsize  : std_logic_vector(2 downto 0);
  signal awburst : std_logic_vector(1 downto 0);
  signal awlock  : std_logic_vector(0 downto 0);
  signal awcache : std_logic_vector(3 downto 0);
  signal awprot  : std_logic_vector(2 downto 0);
  signal awqos   : std_logic_vector(3 downto 0);
  signal awvalid : std_logic;

  signal arid    : std_logic_vector(3 downto 0);
  signal araddr  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal arlen   : std_logic_vector(7 downto 0);
  signal arsize  : std_logic_vector(2 downto 0);
  signal arburst : std_logic_vector(1 downto 0);
  signal arlock  : std_logic_vector(0 downto 0);
  signal arcache : std_logic_vector(3 downto 0);
  signal arprot  : std_logic_vector(2 downto 0);
  signal arqos   : std_logic_vector(3 downto 0);
  signal arvalid : std_logic;

begin
  -- -----------------------------
  -- Write request channel
  -- -----------------------------
  aw_register_slice : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      awid    <= (others => '0');
      awaddr  <= (others => '0');
      awlen   <= (others => '0');
      awsize  <= (others => '0');
      awburst <= (others => '0');
      awlock  <= (others => '0');
      awcache <= (others => '0');
      awprot  <= (others => '0');
      awqos   <= (others => '0');
      awvalid <= '0';
    elsif rising_edge(aclk) then
      awid    <= S00_AXI_awid;
      awaddr  <= S00_AXI_awaddr;
      awlen   <= S00_AXI_awlen;
      awsize  <= S00_AXI_awsize;
      awburst <= S00_AXI_awburst;
      awlock  <= S00_AXI_awlock;
      awcache <= S00_AXI_awcache;
      awprot  <= S00_AXI_awprot;
      awqos   <= S00_AXI_awqos;
      awvalid <= S00_AXI_awvalid;
    end if;
  end process aw_register_slice;

  M00_AXI_awid    <= awid;
  M00_AXI_awaddr  <= awaddr;
  M00_AXI_awlen   <= awlen;
  M00_AXI_awsize  <= awsize;
  M00_AXI_awburst <= awburst;
  M00_AXI_awlock  <= awlock;
  M00_AXI_awcache <= awcache;
  M00_AXI_awprot  <= awprot;
  M00_AXI_awqos   <= awqos;
  -- Handshake
  M00_AXI_awvalid <= awvalid;
  S00_AXI_awready <= M00_AXI_awready;


  -- -----------------------------
  -- Write data channel
  -- -----------------------------
  M00_AXI_wdata  <= S00_AXI_wdata;
  M00_AXI_wstrb  <= S00_AXI_wstrb;
  M00_AXI_wlast  <= S00_AXI_wlast;
  -- Handshake
  M00_AXI_wvalid <= S00_AXI_wvalid;
  S00_AXI_wready <= M00_AXI_wready;


  -- -----------------------------
  -- Write response channel
  -- -----------------------------
  S00_AXI_bid    <= M00_AXI_bid;
  S00_AXI_bresp  <= M00_AXI_bresp;
  -- Handshake
  S00_AXI_bvalid <= M00_AXI_bvalid;
  M00_AXI_bready <= S00_AXI_bready;


  -- -----------------------------
  -- Read request channel
  -- -----------------------------
  ar_register_slice : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      arid    <= (others => '0');
      araddr  <= (others => '0');
      arlen   <= (others => '0');
      arsize  <= (others => '0');
      arburst <= (others => '0');
      arlock  <= (others => '0');
      arcache <= (others => '0');
      arprot  <= (others => '0');
      arqos   <= (others => '0');
      arvalid <= '0';
    elsif rising_edge(aclk) then
      arid    <= S00_AXI_arid;
      araddr  <= S00_AXI_araddr;
      arlen   <= S00_AXI_arlen;
      arsize  <= S00_AXI_arsize;
      arburst <= S00_AXI_arburst;
      arlock  <= S00_AXI_arlock;
      arcache <= S00_AXI_arcache;
      arprot  <= S00_AXI_arprot;
      arqos   <= S00_AXI_arqos;
      arvalid <= S00_AXI_arvalid;
    end if;
  end process ar_register_slice;

  M00_AXI_arid    <= arid;
  M00_AXI_araddr  <= araddr;
  M00_AXI_arlen   <= arlen;
  M00_AXI_arsize  <= arsize;
  M00_AXI_arburst <= arburst;
  M00_AXI_arlock  <= arlock;
  M00_AXI_arcache <= arcache;
  M00_AXI_arprot  <= arprot;
  M00_AXI_arqos   <= arqos;
  -- Handshake
  M00_AXI_arvalid <= arvalid;
  S00_AXI_arready <= M00_AXI_arready;


  -- -----------------------------
  -- Read data channel
  -- -----------------------------
  S00_AXI_rid    <= M00_AXI_rid;
  S00_AXI_rdata  <= M00_AXI_rdata;
  S00_AXI_rresp  <= M00_AXI_rresp;
  S00_AXI_rlast  <= M00_AXI_rlast;
  -- Handshake
  S00_AXI_rvalid <= M00_AXI_rvalid;
  M00_AXI_rready <= S00_AXI_rready;

end architecture behaviour;
