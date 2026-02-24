library ieee;
use ieee.std_logic_1164.all;


entity boot_device_bootcode is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_WEA_WIDTH  : integer := 4);

  port (bootcode_clk    : in std_logic;
        bootcode_rst_n  : in std_logic;
        bootcode_wea_i  : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        bootcode_addr_i : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        bootcode_data_i : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        bootcode_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        bootcode_ev_i   : in std_logic;

        -- UART
        bootcode_rx_i   : in std_logic;
        bootcode_tx_o   : out std_logic;
        bootcode_ctsn_i : in std_logic;
        bootcode_rtsn_o : out std_logic;
        interrupt       : out std_logic);
end entity boot_device_bootcode;


architecture structural of boot_device_bootcode is

  signal app_wea        : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal translator_wea : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal filler_wea     : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);

  signal app_addr        : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal translator_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal filler_addr     : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

  signal app_data        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal translator_data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal filler_data     : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  signal input_wea1, input_wea2   : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal input_addr1, input_addr2 : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_data1, input_data2 : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  signal app_data_read    : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal input_data_read  : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal input_data1_read : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal input_data2_read : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

  signal appdata_mux_ctrl   : std_logic;
  signal inputdata_mux_ctrl : std_logic;

  component boot_device_addrtranslator is
    port (clk                  : in std_logic;
          rst_n                : in std_logic;
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
          inputdata_mux_ctrl_o : out std_logic;
          tr_event_i           : in std_logic);
  end component;

  component boot_device_datafiller is
    port (clk             : in std_logic;
          rst_n           : in std_logic;
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

begin

  boot_dev_addrtranslator_0 : boot_device_addrtranslator
    port map (clk => bootcode_clk,
              rst_n => bootcode_rst_n,
              tr_wea_i => bootcode_wea_i,
              tr_addr_i => bootcode_addr_i,
              tr_data_i => bootcode_data_i,
              tr_app_wea_o => app_wea,
              tr_app_addr_o => app_addr,
              tr_app_data_o => app_data,
              tr_input_wea_o => translator_wea,
              tr_input_addr_o => translator_addr,
              tr_input_data_o => translator_data,
              appdata_mux_ctrl_o => appdata_mux_ctrl,
              inputdata_mux_ctrl_o => inputdata_mux_ctrl,
              tr_event_i => bootcode_ev_i);

  boot_device_datafiller_0 : boot_device_datafiller
    port map (
        clk             => bootcode_clk,
        rst_n           => bootcode_rst_n,
        uart_rx         => bootcode_rx_i,
        uart_tx         => bootcode_tx_o,
        uart_ctsn       => bootcode_ctsn_i,
        uart_rtsn       => bootcode_rtsn_o,
        interrupt       => interrupt,
        fill_wea_o      => filler_wea,
        fill_addr_o     => filler_addr,
        fill_data_o     => filler_data);

  blk_mem_gen_0_instance : blk_mem_gen_0
    port map (clka  => bootcode_clk,
              wea   => app_wea,
              addra => app_addr,
              dina  => app_data,
              douta => app_data_read);

  blk_mem_gen_1_instance : blk_mem_gen_1
    port map (clka  => bootcode_clk,
              wea   => input_wea1,
              addra => input_addr1,
              dina  => input_data1,
              douta => input_data1_read);

  blk_mem_gen_2_instance : blk_mem_gen_1
    port map (clka  => bootcode_clk,
              wea   => input_wea2,
              addra => input_addr2,
              dina  => input_data2,
              douta => input_data2_read);

  bootcode_data_o <= app_data_read when appdata_mux_ctrl = '0' else
                     input_data_read;

  input_data_read <= input_data1_read when inputdata_mux_ctrl = '0' else
                     input_data2_read;

  muxes : process (inputdata_mux_ctrl) is
  begin
    if inputdata_mux_ctrl = '0' then
      input_wea1 <= app_wea;
      input_wea2 <= filler_wea;
      input_addr1 <= app_addr;
      input_addr2 <= filler_addr;
      input_data1 <= app_data;
      input_data2 <= filler_data;
    else
      input_wea1 <= filler_wea;
      input_wea2 <= app_wea;
      input_addr1 <= filler_addr;
      input_addr2 <= app_addr;
      input_data1 <= filler_data;
      input_data2 <= app_data;
    end if;
  end process muxes;

end architecture;
