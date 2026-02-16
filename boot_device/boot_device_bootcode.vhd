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
        bootcode_ev_i   : in std_logic);
end entity boot_device_bootcode;


architecture structural of boot_device_bootcode is

  signal app_wea, input_wea   : std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
  signal app_addr, input_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal app_data_write, input_data_write : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal app_data_read, input_data_read : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal mux_ctrl : std_logic;

  component boot_device_addrtranslator is
    port (clk             : in std_logic;
          rst_n           : in std_logic;
          tr_wea_i        : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_addr_i       : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_data_i       : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          tr_app_wea_o    : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_app_addr_o   : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_app_data_o   : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          tr_input_wea_o  : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          tr_input_addr_o : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          tr_input_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          bram_mux_ctrl   : out std_logic;
          tr_event_i      : in std_logic);
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
              tr_app_data_o => app_data_write,
              tr_input_wea_o => input_wea,
              tr_input_addr_o => input_addr,
              tr_input_data_o => input_data_write,
              bram_mux_ctrl => mux_ctrl,
              tr_event_i => bootcode_ev_i);

  blk_mem_gen_0_instance : blk_mem_gen_0
    port map (clka  => bootcode_clk,
              wea   => app_wea,
              addra => app_addr,
              dina  => app_data_write,
              douta => app_data_read);

  blk_mem_gen_1_instance : blk_mem_gen_1
    port map (clka  => bootcode_clk,
              wea   => input_wea,
              addra => input_addr,
              dina  => input_data_write,
              douta => input_data_read);

  bootcode_data_o <= app_data_read when mux_ctrl = '0' else
                     input_data_read;

end architecture;
