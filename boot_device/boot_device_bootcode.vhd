library ieee;
use ieee.std_logic_1164.all;


entity boot_device_bootcode is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14);

  port (clka  : in std_logic;
        wea   : in std_logic_vector(3 downto 0);
        addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        dina  : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0));
end entity boot_device_bootcode;


architecture structural of boot_device_bootcode is

  component blk_mem_gen_0
    port (clka  : in std_logic;
          wea   : in std_logic_vector(3 downto 0);
          addra : in std_logic_vector(13 downto 0);
          dina  : in std_logic_vector(31 downto 0);
          douta : out std_logic_vector(31 downto 0));
  end component;

begin

  blk_mem_gen_0_instance : blk_mem_gen_0
    port map (clka  => clka,
              wea   => wea,
              addra => addra,
              dina  => dina,
              douta => douta);

end architecture;
