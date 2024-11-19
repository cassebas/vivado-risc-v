library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4_passthrough is
  generic (
    TYPE_WIDTH    : integer := 1;
    EVENTNR_WIDTH : integer := 16;
    COUNTER_WIDTH : integer := 32;
    ARWID_WIDTH   : integer := 4;
    ADDR_WIDTH    : integer := 32;
    DATA_WIDTH    : integer := 64);
  port (
    aclk            : in std_logic;
    aresetn         : in std_logic;
    addr1_monitor_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    addr2_monitor_i : in std_logic_vector(ADDR_WIDTH-1 downto 0);
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

    -- FIFO ports, used for writing read and write requests to dram
    fifo_full_i : in std_logic;
    fifo_din_o  : out std_logic_vector((TYPE_WIDTH +
                                        EVENTNR_WIDTH +
                                        COUNTER_WIDTH*2 +
                                        ARWID_WIDTH +
                                        ADDR_WIDTH +
                                        DATA_WIDTH - 1) downto 0);
    fifo_wren_o : out std_logic);
end axi4_passthrough;


architecture behaviour of axi4_passthrough is

  signal rd_fifo_din : std_logic_vector((TYPE_WIDTH +
                                         EVENTNR_WIDTH +
                                         COUNTER_WIDTH*2 +
                                         ARWID_WIDTH +
                                         ADDR_WIDTH +
                                         DATA_WIDTH - 1) downto 0);
  signal wr_fifo_din : std_logic_vector((TYPE_WIDTH +
                                         EVENTNR_WIDTH +
                                         COUNTER_WIDTH*2 +
                                         ARWID_WIDTH +
                                         ADDR_WIDTH +
                                         DATA_WIDTH - 1) downto 0);
  signal rd_fifo_wren, wr_fifo_wren : std_logic;

  signal cycle_count : unsigned(COUNTER_WIDTH-1 downto 0);
  signal event_count : unsigned(EVENTNR_WIDTH-1 downto 0);

  signal monitor : std_logic;
  signal rd_req_ok, rd_resp_ok : std_logic;
  signal wr_req_ok, wr_data_ok : std_logic;

  -- A single bit will be put into the FIFO for the type of transaction.
  constant rd_transaction : std_logic := '0';
  constant wr_transaction : std_logic := '1';

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


  -- -----------------------------------
  -- Registers to FIFO output signals
  -- -----------------------------------
  fifo_din_o <= rd_fifo_din when rd_fifo_wren = '1' else
                wr_fifo_din when wr_fifo_wren = '1' else
                (others => '1');

  fifo_wren_o <= rd_fifo_wren when rd_fifo_wren = '1' else
                 wr_fifo_wren when wr_fifo_wren = '1' else
                 '0';


  cycle_counter : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      cycle_count <= (others => '0');
    elsif rising_edge(aclk) then
      cycle_count <= cycle_count + 1;
    end if;
  end process cycle_counter;


  enable_fifos : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      rd_fifo_wren <= '0';
      wr_fifo_wren <= '0';
      monitor <= '0';
      event_count <= (0 => '1', others => '0');
    elsif rising_edge(aclk) then
      -- Default value for fifo_wren's, unless special conditions apply
      rd_fifo_wren <= '0';
      wr_fifo_wren <= '0';

      if monitor = '1' then
        -- Read request for addr1 has been seen

        if M00_AXI_rvalid = '1' and S00_AXI_rready = '1' then
          -- Handshake for the Read Data channel

          if rd_fifo_wren = '0' and fifo_full_i = '0' then
            rd_fifo_wren <= '1';

            if M00_AXI_rlast = '1' then
              -- This is the last transfer of the transaction, raise event_count
              -- for the next transaction
              event_count <= event_count + 1;

              -- Maybe reset monitor?
              if S00_AXI_arid = "0010" and S00_AXI_araddr = addr2_monitor_i then
                monitor <= '0';
              end if;
            end if;
          end if;
        end if;

        if M00_AXI_wready = '1' and S00_AXI_wvalid = '1' then
          -- Handshake for the Write Data channel

          if wr_fifo_wren = '0' and fifo_full_i = '0' then
            wr_fifo_wren <= '1';

            if S00_AXI_wlast = '1' then
              -- This is the last transfer of the transaction, raise event_count
              -- for the next transaction
              event_count <= event_count + 1;
            end if;
          end if;
        end if;
      else -- monitor /= '1'
        -- addr1 has not yet been seen
        if M00_AXI_rvalid = '1' and S00_AXI_rready = '1' then
          -- addr1 is being requested! This is a read request. Since we were
          -- not monitoring yet, we don't have to look at the AXI write req
          -- signals.
          if S00_AXI_arid = "0010" and S00_AXI_araddr = addr1_monitor_i then
            monitor <= '1';

            if rd_fifo_wren = '0' and fifo_full_i = '0' then
              rd_fifo_wren <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process enable_fifos;


  read_request_register : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      rd_fifo_din <= (others => '0');
      rd_req_ok <= '0';
      rd_resp_ok <= '0';
    elsif rising_edge(aclk) then

      if S00_AXI_arvalid = '1' and M00_AXI_arready = '1' then
        -- Handshake for the Read Request channel

        if rd_req_ok /= '1' then
          -- --
          -- Read request had not been registered yet
          --
          -- Save the type of request (READ)
          rd_fifo_din(TYPE_WIDTH +
                      EVENTNR_WIDTH +
                      COUNTER_WIDTH*2 +
                      ARWID_WIDTH +
                      ADDR_WIDTH +
                      DATA_WIDTH - 1) <= rd_transaction;

          -- Save the event number
          rd_fifo_din((EVENTNR_WIDTH +
                       COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(event_count);

          -- Save the number of cycles spent up until now
          rd_fifo_din((COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (COUNTER_WIDTH +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(cycle_count);

          -- Save the arid (transaction identifier of the read request)
          rd_fifo_din((ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (ADDR_WIDTH +
                       DATA_WIDTH)) <= S00_AXI_arid;

          -- Save the araddr (request read address)
          rd_fifo_din((ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (DATA_WIDTH)) <= S00_AXI_araddr;

          -- Set rd_req_ok since the request has been logged now
          rd_req_ok <= '1';
        end if;
      else
        -- Reset rd_req_ok for the next request
        rd_req_ok <= '0';
      end if;

      --
      -- Answer from DRAM memory
      --
      if M00_AXI_rvalid = '1' and S00_AXI_rready = '1' then
        -- Handshake for the Read Data channel

        if rd_resp_ok /= '1' then
          -- Save the number of cycles spent up until now
          rd_fifo_din((COUNTER_WIDTH +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(cycle_count);

          -- Save the rdata (the data from memory)
          rd_fifo_din(DATA_WIDTH-1 downto 0) <= M00_AXI_rdata;

          -- Set the rd_resp_ok since the response has been registered now
          rd_resp_ok <= '1';
        end if;
      else
        -- Reset rd_resp_ok for the next response
        rd_resp_ok <= '0';
      end if;
    end if;
  end process read_request_register;


  write_request_register : process(aclk, aresetn) is
  begin
    if aresetn = '0' then
      wr_fifo_din <= (others => '0');
      wr_req_ok <= '0';
      wr_data_ok <= '0';
    elsif rising_edge(aclk) then

      if S00_AXI_awvalid = '1' and M00_AXI_awready = '1' then
        -- Handshake for the Write Request channel

        if wr_req_ok /= '1' then
          -- --
          -- Write request had not been registered yet
          --
          -- Save the type of request (WRITE)
          wr_fifo_din(TYPE_WIDTH +
                      EVENTNR_WIDTH +
                      COUNTER_WIDTH*2 +
                      ARWID_WIDTH +
                      ADDR_WIDTH +
                      DATA_WIDTH - 1) <= wr_transaction;

          -- Save the event number
          wr_fifo_din((EVENTNR_WIDTH +
                       COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(event_count);

          -- Save the number of cycles spent up until now
          wr_fifo_din((COUNTER_WIDTH*2 +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (COUNTER_WIDTH +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(cycle_count);


          -- Save the awid (transaction identifier of the write request)
          wr_fifo_din((ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (ADDR_WIDTH +
                       DATA_WIDTH)) <= S00_AXI_awid;

          -- Save the awaddr (request write address)
          wr_fifo_din((ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (DATA_WIDTH)) <= S00_AXI_awaddr;

          -- Set rd_req_ok since the request has been logged now
          wr_req_ok <= '1';
        end if;
      else
        -- Reset rd_req_ok for the next request
        wr_req_ok <= '0';
      end if;

      --
      -- Write Data channel
      --
      if M00_AXI_wready = '1' and S00_AXI_wvalid = '1' then
        -- Handshake for the Write Data channel

        if wr_data_ok /= '1' then
          -- Save the wdata (the data being written to memory)
          wr_fifo_din(DATA_WIDTH-1 downto 0) <= S00_AXI_wdata;

          -- Save the number of cycles spent up until now
          wr_fifo_din((COUNTER_WIDTH +
                       ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH - 1) downto
                      (ARWID_WIDTH +
                       ADDR_WIDTH +
                       DATA_WIDTH)) <= std_logic_vector(cycle_count);

          wr_data_ok <= '1';
        end if;
      else
        -- Reset wr_data_ok for the next data
        wr_data_ok <= '0';
      end if;

    end if;
  end process write_request_register;

end architecture behaviour;
