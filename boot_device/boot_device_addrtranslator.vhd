library ieee;
use ieee.std_logic_1164.all;


entity boot_device_addrtranslator is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_WEA_WIDTH  : integer := 4);

  port (clk             : in std_logic;
        tr_wea_i        : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        tr_addr_i       : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        tr_data_i       : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        tr_app_wea_o    : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        tr_app_addr_o   : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        tr_app_data_o   : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        tr_input_wea_o  : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        tr_input_addr_o : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        tr_input_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        bram_mux_ctrl   : out std_logic);
end entity boot_device_addrtranslator;


architecture structural of boot_device_addrtranslator is

begin

  -- For now hardcoded passthrough of signals to app's block ram
  tr_app_wea_o <= tr_wea_i;
  tr_app_addr_o <= tr_addr_i;
  tr_app_data_o <= tr_data_i;

  tr_input_wea_o <= (others => '0');
  tr_input_addr_o <= (others => '0');
  tr_input_data_o <= (others => '0');

  -- Select first Block RAM's output ('0' => blk_mem_gen_0, '1' => blk_mem_gen_1)
  bram_mux_ctrl <= '0';

end architecture;
