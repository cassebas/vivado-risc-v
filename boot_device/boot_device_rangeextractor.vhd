library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_rangeextractor is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM0_ADDR_WIDTH : integer := 14;
           BRAM1_ADDR_WIDTH : integer := 16;
           BRAM_WEA_WIDTH  : integer := 4);

  port (clk           : in std_logic;
        rst_n         : in std_logic;
        cpu_reset_n   : in std_logic;
        rng_wea_i     : in std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        rng_addr_i    : in std_logic_vector(BRAM0_ADDR_WIDTH-1 downto 0);
        rng_data_i    : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        rng_wea_o     : out std_logic_vector(BRAM_WEA_WIDTH-1 downto 0);
        rng_addr_o    : out std_logic_vector(BRAM0_ADDR_WIDTH-1 downto 0);
        rng_data_o    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        -- These outputs go to the addrtranslator, they are dynamically set
        array_start_o : out std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0);
        array_end_o   : out std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0);
        array_size_o  : out std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0));
end entity boot_device_rangeextractor;


architecture structural of boot_device_rangeextractor is

  -- These are addresses of the MMIO (BRAM) addresses where the
  -- ranges are stored of the input values located in the ELF
  -- binary.
  constant INPUT_ARRAY_START_ADDR : integer := 16#FC0C#;
  constant INPUT_ARRAY_END_ADDR   : integer := 16#FC10#;
  constant INPUT_ARRAY_SIZE_ADDR  : integer := 16#FC14#;

  -- The input address converted to unsigned
  signal rng_addr  : unsigned(BRAM0_ADDR_WIDTH-1 downto 0);

  -- These signals will be filled with the values that are put in the configuration
  -- section of the BRAM dynamically at runtime. (Located at offset 0x0000fc00).
  --
  -- The initial values of the signals are high, such that they will not
  -- interfere with downloading the ELF binary at lower addresses.
  signal array_start : std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0) := (others => '1');
  signal array_end   : std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0) := (others => '1');
  signal array_size  : std_logic_vector(BRAM1_ADDR_WIDTH-1 downto 0) := (others => '0');

begin

  -- Simple passthrough of the BRAM inputs
  rng_wea_o  <= rng_wea_i;
  rng_addr_o <= rng_addr_i;
  rng_data_o <= rng_data_i;

  -- Convert the address to unsigned
  rng_addr <= unsigned(rng_addr_i);

  -- Fill the input range parameters dynamically at runtime, during the
  -- bootstrap process.
  bootstrap_range_extract : process(clk) is
  begin
    if rising_edge(clk) then
      -- Only update the addresses if this is a write request.
      if rng_wea_i(0) = '1' then
        if rng_addr = INPUT_ARRAY_START_ADDR then
          array_start <= rng_data_i(array_start'high downto array_start'low);
        elsif rng_addr = INPUT_ARRAY_END_ADDR then
          array_end <= rng_data_i(array_end'high downto array_end'low);
        elsif rng_addr = INPUT_ARRAY_SIZE_ADDR then
          array_size <= rng_data_i(array_size'high downto array_size'low);
        end if;
      end if;
    end if;
  end process bootstrap_range_extract;

  array_start_o <= array_start;
  array_end_o   <= array_end;
  array_size_o  <= array_size;

end architecture;
