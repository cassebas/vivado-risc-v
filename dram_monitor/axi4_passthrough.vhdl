library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4_passthrough is
  generic (
    ADDR_WIDTH    : integer := 32;
    DATA_WIDTH    : integer := 64;
    COUNTER_WIDTH : integer := 32;
    EVENTNR_WIDTH : integer := 16);
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
    M00_AXI_rready  : out std_logic;

    -- FIFO ports, used for writing read request addresses
    fifo_full_i : in std_logic;
    fifo_din_o  : out std_logic_vector((ADDR_WIDTH +
                                        DATA_WIDTH +
                                        COUNTER_WIDTH*2 +
                                        EVENTNR_WIDTH + 4)-1 downto 0);
    fifo_wren_o : out std_logic);
end axi4_passthrough;

architecture behaviour of axi4_passthrough is

  signal fifo_din  : std_logic_vector((ADDR_WIDTH +
                                       DATA_WIDTH +
                                       COUNTER_WIDTH*2 +
                                       EVENTNR_WIDTH + 4)-1 downto 0);
  signal fifo_wren : std_logic;

  signal cycle_count : unsigned(COUNTER_WIDTH-1 downto 0);
  signal event_count : unsigned(EVENTNR_WIDTH-1 downto 0);

begin
  -- -- -----------------------------
  -- -- Write request channel
  -- -- -----------------------------
  M00_AXI_awid    <= S00_AXI_awid;
  M00_AXI_awaddr  <= S00_AXI_awaddr;
  M00_AXI_awlen   <= S00_AXI_awlen;
  M00_AXI_awsize  <= S00_AXI_awsize;
  M00_AXI_awburst <= S00_AXI_awburst;
  M00_AXI_awlock  <= S00_AXI_awlock;
  M00_AXI_awcache <= S00_AXI_awcache;
  M00_AXI_awprot  <= S00_AXI_awprot;
  M00_AXI_awqos   <= S00_AXI_awqos;
  -- Handshake
  M00_AXI_awvalid <= S00_AXI_awvalid;
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


  -- -- -----------------------------
  -- -- Read request channel
  -- -- -----------------------------
  M00_AXI_arid    <= S00_AXI_arid;
  M00_AXI_araddr  <= S00_AXI_araddr;
  M00_AXI_arlen   <= S00_AXI_arlen;
  M00_AXI_arsize  <= S00_AXI_arsize;
  M00_AXI_arburst <= S00_AXI_arburst;
  M00_AXI_arlock  <= S00_AXI_arlock;
  M00_AXI_arcache <= S00_AXI_arcache;
  M00_AXI_arprot  <= S00_AXI_arprot;
  M00_AXI_arqos   <= S00_AXI_arqos;
  -- Handshake
  M00_AXI_arvalid <= S00_AXI_arvalid;
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


  -- Register to FIFO output signals
  fifo_din_o <= fifo_din;
  fifo_wren_o <= fifo_wren;

  enable_fifo : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      fifo_wren <= '0';
    elsif rising_edge(aclk) then
      if fifo_wren = '0' and fifo_full_i = '0' then
        if M00_AXI_rvalid = '1' and S00_AXI_rready = '1' then
          if S00_AXI_awsize = "011" and S00_AXI_awlen = "00000111" then
            fifo_wren <= '1';
          end if;
        end if;
      else
        fifo_wren <= '0';
      end if;
    end if;
  end process enable_fifo;


  read_araddr_rdata : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      fifo_din <= (others => '0');
      cycle_count <= (others => '0');
      event_count <= (0 => '1', others => '0');
    elsif rising_edge(aclk) then
      cycle_count <= cycle_count + 1;

      if S00_AXI_arvalid = '1' and M00_AXI_arready = '1' then
        event_count <= event_count + 1;
        -- --
        -- Read request accepted, this is the start of the transfer
        --
        -- Save the event number
        fifo_din((ADDR_WIDTH +
                  DATA_WIDTH +
                  COUNTER_WIDTH*2 +
                  EVENTNR_WIDTH + 4) - 1 downto
                 (ADDR_WIDTH +
                  DATA_WIDTH +
                  COUNTER_WIDTH*2 + 4)) <= std_logic_vector(event_count);
        -- Save the number of cycles spent up until now
        fifo_din((ADDR_WIDTH +
                  DATA_WIDTH +
                  COUNTER_WIDTH*2 + 4) - 1 downto
                 (ADDR_WIDTH +
                  DATA_WIDTH +
                  COUNTER_WIDTH + 4)) <= std_logic_vector(cycle_count);
        -- Save the arid (transaction identifier of the read request)
        fifo_din((ADDR_WIDTH +
                  DATA_WIDTH + 4) - 1 downto
                 (ADDR_WIDTH +
                  DATA_WIDTH)) <= S00_AXI_arid;
        -- Save the araddr (request read address)
        fifo_din((ADDR_WIDTH +
                  DATA_WIDTH) - 1 downto DATA_WIDTH) <= S00_AXI_araddr;
      end if;

      --
      -- Answer from DRAM memory
      --
      if M00_AXI_rvalid = '1' and S00_AXI_rready = '1' then
        -- Save the number of cycles spent up until now
        fifo_din((ADDR_WIDTH +
                  DATA_WIDTH +
                  COUNTER_WIDTH + 4) - 1 downto
                 (ADDR_WIDTH +
                  DATA_WIDTH + 4)) <= std_logic_vector(cycle_count);

        -- Save the rdata (the data from memory)
        fifo_din(DATA_WIDTH-1 downto 0) <= M00_AXI_rdata;
      end if;
    end if;
  end process read_araddr_rdata;


end architecture behaviour;
