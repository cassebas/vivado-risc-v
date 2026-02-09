library ieee;
use ieee.std_logic_1164.all;


entity boot_device_bootcode is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_WEA_WIDTH  : integer := 4);

  port (bootcode_clk    : in std_logic;
        bootcode_wea_i  : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        bootcode_addr_i : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        bootcode_data_i : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        bootcode_data_o : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
end entity boot_device_bootcode;


architecture structural of boot_device_bootcode is

  component blk_mem_gen_0
    port (clka  : in std_logic;
          wea   : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
          addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
  end component;

begin

  blk_mem_gen_0_instance : blk_mem_gen_0
    port map (clka  => bootcode_clk,
              wea   => bootcode_wea_i,
              addra => bootcode_addr_i,
              dina  => bootcode_data_i,
              douta => bootcode_data_o);

end architecture;
