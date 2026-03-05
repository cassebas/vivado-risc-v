library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device is

  generic (S_AXI_DATA_WIDTH : integer   := 32;
           S_AXI_ADDR_WIDTH : integer   := 16;
           BRAM_SIZE        : integer   := 128;
           BLOCK_SIZE       : integer   := 16);

  port (cpu_reset_n     : in std_logic;  --  CPU reset, active low

        -- UART
        rx_i            : in std_logic;
        tx_o            : out std_logic;
        ctsn_i          : in std_logic;
        rtsn_o          : out std_logic;
        interrupt       : out std_logic;

        -- LEDs (debug)
        led_out         : out std_logic_vector(7 downto 0);

        S00_AXI_aclk    : in std_logic;  --  AXI clock
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
        -- S00_AXI_awqos   : in std_logic_vector(3 downto 0);
        -- Handshake
        S00_AXI_awvalid : in std_logic;
        S00_AXI_awready : out std_logic;

        -- -----------------------------
        --  Write data channel
        -- -----------------------------
        S00_AXI_wdata   : in std_logic_vector(S_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_wstrb   : in std_logic_vector((S_AXI_DATA_WIDTH/8)-1 downto 0);
        -- S00_AXI_wlast   : in std_logic;
        -- Handshake
        S00_AXI_wvalid  : in std_logic;
        S00_AXI_wready  : out std_logic;

        -- -----------------------------
        --  Write response channel
        -- -----------------------------
        -- S00_AXI_bid     : out std_logic_vector(3 downto 0);
        S00_AXI_bresp   : out std_logic_vector(1 downto 0);
        -- Handshake
        S00_AXI_bvalid  : out std_logic;
        S00_AXI_bready  : in std_logic;

        -- -----------------------------
        -- Read request channel
        -- -----------------------------
        -- S00_AXI_arid    : in std_logic_vector(3 downto 0);
        S00_AXI_araddr  : in std_logic_vector(S_AXI_ADDR_WIDTH-1 downto 0);
        -- S00_AXI_arlen   : in std_logic_vector(7 downto 0);
        -- S00_AXI_arsize  : in std_logic_vector(2 downto 0);
        -- S00_AXI_arburst : in std_logic_vector(1 downto 0);
        -- S00_AXI_arlock  : in std_logic_vector(0 downto 0);
        -- S00_AXI_arcache : in std_logic_vector(3 downto 0);
        S00_AXI_arprot  : in std_logic_vector(2 downto 0);
        -- S00_AXI_arqos   : in std_logic_vector(3 downto 0);
        -- Handshake
        S00_AXI_arvalid : in std_logic;
        S00_AXI_arready : out std_logic;

        -- -----------------------------
        -- Read data channel
        -- -----------------------------
        -- S00_AXI_rid     : out std_logic_vector(3 downto 0);
        S00_AXI_rdata   : out std_logic_vector(S_AXI_DATA_WIDTH-1 downto 0);
        S00_AXI_rresp   : out std_logic_vector(1 downto 0);
        -- S00_AXI_rlast   : out std_logic;
        -- Handshake
        S00_AXI_rvalid  : out std_logic;
        S00_AXI_rready  : in std_logic);
end boot_device;


architecture behavior of boot_device is

  -- local parameter for addressing 32 bit / 64 bit BD_AXISLAVE_DATA_WIDTH
  -- ADDR_LSB is used for addressing 32/64 bit registers/memories
  -- ADDR_LSB = 2 for 32 bits (n downto 2)
  -- ADDR_LSB = 3 for 64 bits (n downto 3)
  constant ADDR_LSB  : integer := (S_AXI_DATA_WIDTH/32)+ 1;

  constant BRAM_DATA_WIDTH : integer := S_AXI_DATA_WIDTH;
  constant BRAM_ADDR_WIDTH : integer := S_AXI_ADDR_WIDTH - ADDR_LSB;
  constant BRAM_WEA_WIDTH  : integer := 4;

  component boot_device_axislave is
    generic (BD_AXISLAVE_DATA_WIDTH : integer;
             BD_AXISLAVE_ADDR_WIDTH : integer;
             BD_AXISLAVE_WEA_WIDTH  : integer);

    port (axislave_addr_o : out std_logic_vector(BD_AXISLAVE_ADDR_WIDTH-1 downto 0);
          axislave_data_i : in std_logic_vector(BD_AXISLAVE_DATA_WIDTH-1 downto 0);
          axislave_data_o : out std_logic_vector(BD_AXISLAVE_DATA_WIDTH-1 downto 0);
          axislave_wea_o  : out std_logic_vector(BD_AXISLAVE_WEA_WIDTH-1 downto 0);

          S_AXI_aclk    : in std_logic;
          S_AXI_aresetn : in std_logic;
          S_AXI_awaddr  : in std_logic_vector(BD_AXISLAVE_ADDR_WIDTH-1 downto 0);
          S_AXI_awprot  : in std_logic_vector(2 downto 0);
          S_AXI_awvalid : in std_logic;
          S_AXI_awready : out std_logic;
          S_AXI_wdata   : in std_logic_vector(BD_AXISLAVE_DATA_WIDTH-1 downto 0);
          S_AXI_wstrb   : in std_logic_vector((BD_AXISLAVE_DATA_WIDTH/8)-1 downto 0);
          S_AXI_wvalid  : in std_logic;
          S_AXI_wready  : out std_logic;
          S_AXI_bresp   : out std_logic_vector(1 downto 0);
          S_AXI_bvalid  : out std_logic;
          S_AXI_bready  : in std_logic;
          S_AXI_araddr  : in std_logic_vector(BD_AXISLAVE_ADDR_WIDTH-1 downto 0);
          S_AXI_arprot  : in std_logic_vector(2 downto 0);
          S_AXI_arvalid : in std_logic;
          S_AXI_arready : out std_logic;
          S_AXI_rdata   : out std_logic_vector(BD_AXISLAVE_DATA_WIDTH-1 downto 0);
          S_AXI_rresp   : out std_logic_vector(1 downto 0);
          S_AXI_rvalid  : out std_logic;
          S_AXI_rready  : in std_logic);
  end component boot_device_axislave;

  component boot_device_addrtranslator is
    generic (BRAM_SIZE  : integer;
             BLOCK_SIZE : integer);

    port (clk                  : in std_logic;
          rst_n                : in std_logic;
          cpu_reset_n          : in std_logic;
          tr_wea_i             : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_addr_i            : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_data_i            : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          tr_app_wea_o         : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_app_addr_o        : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_app_data_o        : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          tr_input_wea_o       : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_input_addr_o      : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_input_data_o      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          appdata_mux_ctrl_o   : out std_logic;
          inputdata_mux_ctrl_o : out std_logic);
  end component;

  component boot_device_datafiller is
    generic (BRAM_SIZE  : integer;
             BLOCK_SIZE : integer);

    port (clk             : in std_logic;
          rst_n           : in std_logic;
          cpu_reset_n     : in std_logic;
          led_out         : out std_logic_vector(7 downto 0);
          uart_rx         : in std_logic;
          uart_tx         : out std_logic;
          uart_ctsn       : in std_logic;
          uart_rtsn       : out std_logic;
          interrupt       : out std_logic;
          fill_wea_o      : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          fill_addr_o     : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          fill_data_o     : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component;

  component blk_mem_gen_0
    port (clka  : in std_logic;
          wea   : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component;

  component blk_mem_gen_1
    port (clka  : in std_logic;
          wea   : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component;

  component blk_mem_gen_2
    port (clka  : in std_logic;
          wea   : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component;

  -- These are the signals coming out of the boot_device_axislave component,
  -- requesting data from a certain address.
  -- They go into the boot_device_addr_translator block.
  signal wea        : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal addr       : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal data_write : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal data_read  : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- These signals come out of the boot_device_addr_translator_block,
  -- they are split into 'app' addr/data for application data from the ELF
  -- file and 'read' addr/data for requested input data.
  signal app_wea        : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal app_addr        : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal app_data        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal read_wea : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal read_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal read_data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- These signals come out of the boot_device_addr_datafiller,
  -- they are 'write' addr/data for input data to be written.
  signal write_wea     : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal write_addr     : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal write_data     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- These signals are the output of the muxes that are connected as inputs
  -- to the two input data block RAMs.
  signal input_wea1, input_wea2   : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal input_addr1, input_addr2 : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_data1, input_data2 : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- Output signal of the first block RAM that contains the ELF file.
  signal app_data_read    : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  -- Output signals of the second/third block RAMS containing input data.
  signal input_data1_read : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal input_data2_read : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- Output signal of the mux to choose from the 2nd or 3rd input data block RAM.
  signal input_data_read  : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  -- Signal that controls the mux to select data to read from the first block RAM
  -- with ELF data or the 2nd/3rd block RAM containing input data.
  signal appdata_mux_ctrl   : std_logic;

  -- Signal that controls the mux to select data to read from the 2nd or 3rd
  -- block RAM containing input data.
  signal inputdata_mux_ctrl : std_logic;

begin

  boot_device_axislave_inst : boot_device_axislave
    generic map (BD_AXISLAVE_DATA_WIDTH => S_AXI_DATA_WIDTH,
                 BD_AXISLAVE_ADDR_WIDTH => BRAM_ADDR_WIDTH,
                 BD_AXISLAVE_WEA_WIDTH  => BRAM_WEA_WIDTH)

    port map (axislave_addr_o => addr,
              axislave_data_i => data_read,
              axislave_data_o => data_write,
              axislave_wea_o  => wea,

              S_AXI_aclk    => s00_axi_aclk,
              S_AXI_aresetn => s00_axi_aresetn,
              S_AXI_awaddr  => s00_axi_awaddr(S_AXI_ADDR_WIDTH-1 downto ADDR_LSB),
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
              S_AXI_araddr  => s00_axi_araddr(S_AXI_ADDR_WIDTH-1 downto ADDR_LSB),
              S_AXI_arprot  => s00_axi_arprot,
              S_AXI_arvalid => s00_axi_arvalid,
              S_AXI_arready => s00_axi_arready,
              S_AXI_rdata   => s00_axi_rdata,
              S_AXI_rresp   => s00_axi_rresp,
              S_AXI_rvalid  => s00_axi_rvalid,
              S_AXI_rready  => s00_axi_rready);


  boot_dev_addrtranslator_0 : boot_device_addrtranslator
    generic map (BRAM_SIZE  => BRAM_SIZE,
                 BLOCK_SIZE => BLOCK_SIZE)

    port map (clk                  => S00_AXI_aclk,
              rst_n                => S00_AXI_aresetn,
              cpu_reset_n          => cpu_reset_n,
              tr_wea_i             => wea,
              tr_addr_i            => addr,
              tr_data_i            => data_write,
              tr_app_wea_o         => app_wea,
              tr_app_addr_o        => app_addr,
              tr_app_data_o        => app_data,
              tr_input_wea_o       => read_wea,
              tr_input_addr_o      => read_addr,
              tr_input_data_o      => read_data,
              appdata_mux_ctrl_o   => appdata_mux_ctrl,
              inputdata_mux_ctrl_o => inputdata_mux_ctrl);


  boot_device_datafiller_0 : boot_device_datafiller
    generic map (BRAM_SIZE  => BRAM_SIZE,
                 BLOCK_SIZE => BLOCK_SIZE)

    port map (
        clk         => S00_AXI_aclk,
        rst_n       => S00_AXI_aresetn,
        cpu_reset_n => cpu_reset_n,
        led_out     => led_out,
        uart_rx     => rx_i,
        uart_tx     => tx_o,
        uart_ctsn   => ctsn_i,
        uart_rtsn   => rtsn_o,
        interrupt   => interrupt,
        fill_wea_o  => write_wea,
        fill_addr_o => write_addr,
        fill_data_o => write_data);


  blk_mem_gen_0_instance : blk_mem_gen_0
    port map (clka  => S00_AXI_aclk,
              wea   => app_wea,
              addra => app_addr,
              dina  => app_data,
              douta => app_data_read);

  blk_mem_gen_1_instance : blk_mem_gen_1
    port map (clka  => S00_AXI_aclk,
              wea   => input_wea1,
              addra => input_addr1,
              dina  => input_data1,
              douta => input_data1_read);

  blk_mem_gen_2_instance : blk_mem_gen_2
    port map (clka  => S00_AXI_aclk,
              wea   => input_wea2,
              addra => input_addr2,
              dina  => input_data2,
              douta => input_data2_read);


  data_read <= app_data_read when appdata_mux_ctrl = '0' else
               input_data_read;

  input_data_read <= input_data1_read when inputdata_mux_ctrl = '0' else
                     input_data2_read;


  inputdata_bram_muxes : process (inputdata_mux_ctrl) is
  begin
    if inputdata_mux_ctrl = '0' then
      input_wea1  <= read_wea;
      input_wea2  <= write_wea;
      input_addr1 <= read_addr;
      input_addr2 <= write_addr;
      input_data1 <= read_data;
      input_data2 <= write_data;
    else
      input_wea1  <= write_wea;
      input_wea2  <= read_wea;
      input_addr1 <= write_addr;
      input_addr2 <= read_addr;
      input_data1 <= write_data;
      input_data2 <= read_data;
    end if;
  end process inputdata_bram_muxes;

end architecture behavior;
