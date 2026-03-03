library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_addrtranslator is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_WEA_WIDTH  : integer := 4;

           INPUT_IDX_LEN   : integer := 16;
           INPUT_IDX_LO    : integer := 16#5C7#;
           INPUT_IDX_HI    : integer := 16#5D7# - 1);

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

  signal addr_idx_input  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal addr_idx_new    : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal addr_idx_offset : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal addr_idx_offset_nxt : unsigned(BRAM_ADDR_WIDTH-1 downto 0);

  -- Block size 16 (for 14 bits) is 00_0000_0001_0000
  constant BLOCK_SIZE : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (4 => '1',
                                                                 others => '0');

  -- -- Maximum offset (for 14 bits) is 11_1111_1111_0000
  -- constant MAX_OFFSET : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (3 => '0',
  --                                                                2 => '0',
  --                                                                1 => '0',
  --                                                                0 => '0',
  --                                                                others => '1');

  -- TESTING: Smaller maximum offset (for 14 bits) is 00_0011_1111_0000 (1008)
  -- after 64 runs index will reach 1023, 65th run will start from the other
  -- block RAM.
  constant MAX_OFFSET : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (9 => '1',
                                                                 8 => '1',
                                                                 7 => '1',
                                                                 6 => '1',
                                                                 5 => '1',
                                                                 4 => '1',
                                                                 others => '0');

  signal reset_active : std_logic;

  signal appdata_mux_ctrl   : std_logic;
  signal inputdata_mux_ctrl : std_logic := '0';

begin

  tr_app_wea_o <= tr_wea_i;
  tr_app_addr_o <= tr_addr_i;
  tr_app_data_o <= tr_data_i;

  tr_input_wea_o <= tr_wea_i;
  tr_input_addr_o <= std_logic_vector(addr_idx_new);
  tr_input_data_o <= tr_data_i;

  addr_idx_new <= addr_idx_input - INPUT_IDX_LO + addr_idx_offset;
  addr_idx_offset_nxt <= addr_idx_offset + BLOCK_SIZE;

  appdata_mux_ctrl_o <= appdata_mux_ctrl;
  inputdata_mux_ctrl_o <= inputdata_mux_ctrl;

  compute_offset : process (clk) is
  begin
    if rising_edge(clk) then
      if cpu_reset_n = '0' then
        -- Only increase offset upon a *new* reset event
        if reset_active = '0' then
          addr_idx_offset <= addr_idx_offset_nxt;
          if addr_idx_offset = MAX_OFFSET then
            addr_idx_offset <= (others => '0');
            inputdata_mux_ctrl <= not inputdata_mux_ctrl;
          end if;
          reset_active <= '1';
        end if;
      else
        reset_active <= '0';
      end if;
    end if;
  end process compute_offset;

  addr_idx_input <= unsigned(tr_addr_i);

  -- Select one of the Block RAMs' output ('0' => blk_mem_gen_0, '1' => blk_mem_gen_1)
  mux_ctrl_proc : process(addr_idx_input) is
  begin
    if INPUT_IDX_LO <= addr_idx_input and addr_idx_input <= INPUT_IDX_HI then
      -- Must be the input data located between 0x600505BB and 0x600505CB-1
      appdata_mux_ctrl <= '1';
    else
      appdata_mux_ctrl <= '0';
    end if;
  end process mux_ctrl_proc;

end architecture;
