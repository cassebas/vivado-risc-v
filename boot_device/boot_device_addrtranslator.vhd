library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_addrtranslator is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 16;
           BRAM_WEA_WIDTH  : integer := 4;
           BRAM_SIZE       : integer := 4096);

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
end entity boot_device_addrtranslator;


architecture structural of boot_device_addrtranslator is

  signal tr_addr  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_addr    : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_addr_offset : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal input_addr_offset_nxt : unsigned(BRAM_ADDR_WIDTH-1 downto 0);

  -- These are addresses of the MMIO (BRAM) addresses where the
  -- ranges are stored of the input values located in the ELF
  -- binary.
  constant ADDR_INPUT_ARRAY_LO : integer := 16#FC0C#;
  constant ADDR_INPUT_ARRAY_HI : integer := 16#FC10#;
  constant ADDR_ARRAY_SIZE     : integer := 16#FC14#;

  signal reset_active : std_logic;

  signal appdata_mux_ctrl   : std_logic;
  signal inputdata_mux_ctrl : std_logic := '0';

  -- These signals will be filled with the values that are put in the BRAM
  -- dynamically at runtime. Initial values are high, such that they will not
  -- interfere with downloading the ELF binary at lower addresses.
  signal addr_array_lo : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1');
  signal addr_array_hi : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1');
  signal array_size    : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

  signal max_offset  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
begin

  tr_app_wea_o <= tr_wea_i;
  tr_app_addr_o <= tr_addr_i;
  tr_app_data_o <= tr_data_i;

  tr_input_wea_o <= tr_wea_i;
  tr_input_addr_o <= std_logic_vector(input_addr);
  tr_input_data_o <= tr_data_i;
  tr_addr <= unsigned(tr_addr_i);

  input_addr <= tr_addr - addr_array_lo + input_addr_offset;
  input_addr_offset_nxt <= input_addr_offset + array_size;
  max_offset <= BRAM_SIZE - array_size;

  appdata_mux_ctrl_o <= appdata_mux_ctrl;
  inputdata_mux_ctrl_o <= inputdata_mux_ctrl;

  compute_offset : process (clk) is
  begin
    if rising_edge(clk) then
      if cpu_reset_n = '0' then
        -- Only increase offset upon a *new* reset event
        if reset_active = '0' then
          input_addr_offset <= input_addr_offset_nxt;
          if input_addr_offset = max_offset then
            input_addr_offset <= (others => '0');
            inputdata_mux_ctrl <= not inputdata_mux_ctrl;
          end if;
          reset_active <= '1';
        end if;
      else
        reset_active <= '0';
      end if;
    end if;
  end process compute_offset;

  -- Select one of the Block RAMs' output
  -- ('0' => blk_mem_app_0/1, '1' => blk_mem_data_0/1)
  mux_ctrl_proc : process(tr_addr) is
  begin
    if addr_array_lo <= tr_addr and tr_addr <= addr_array_hi then
      appdata_mux_ctrl <= '1';
    else
      appdata_mux_ctrl <= '0';
    end if;
  end process mux_ctrl_proc;

  -- Fill the input range parameters dynamically at runtime, during the
  -- bootstrap process.
  bootstrap_filter_addr_idx : process(clk) is
  begin
    if rising_edge(clk) then
      -- Only update the addresses if this is a write request.
      if tr_wea_i(0) = '1' then
        if tr_addr = ADDR_INPUT_ARRAY_LO then
          addr_array_lo <=
            unsigned(tr_data_i(addr_array_lo'high downto addr_array_lo'low));
        elsif tr_addr = ADDR_INPUT_ARRAY_HI then
          addr_array_hi <=
            unsigned(tr_data_i(addr_array_hi'high downto addr_array_hi'low));
        elsif tr_addr = ADDR_ARRAY_SIZE then
          array_size <=
            unsigned(tr_data_i(array_size'high downto array_size'low));
        end if;
      end if;
    end if;
  end process bootstrap_filter_addr_idx;

end architecture;
