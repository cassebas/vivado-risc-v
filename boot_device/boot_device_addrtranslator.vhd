library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_addrtranslator is
  generic (BRAM_DATA_WIDTH : integer := 32;
           BRAM_ADDR_WIDTH : integer := 14;
           BRAM_WEA_WIDTH  : integer := 4;

           INPUT_IDX_LEN   : integer := 16;
           INPUT_IDX_LO    : integer := 16#5BB#;
           INPUT_IDX_HI    : integer := 16#5CB# - 1);

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
end entity boot_device_addrtranslator;


architecture structural of boot_device_addrtranslator is

  signal addr_idx_input  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal addr_idx_offset : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal addr_idx_new    : unsigned(BRAM_ADDR_WIDTH-1 downto 0);

  constant BLOCK_SIZE : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := "00000000000010";

begin

  tr_app_wea_o <= tr_wea_i;
  tr_app_addr_o <= tr_addr_i;
  tr_app_data_o <= tr_data_i;

  tr_input_wea_o <= tr_wea_i;
  tr_input_addr_o <= std_logic_vector(addr_idx_new);
  tr_input_data_o <= tr_data_i;

  -- Convert the incoming address from std_logic_vector to unsigned
  addr_idx_input <= unsigned(tr_addr_i);
  addr_idx_new <= addr_idx_input + addr_idx_offset;

  compute_offset : process (clk, rst_n) is
  begin
    if rst_n = '0' then
      addr_idx_offset <= (others => '0');
    elsif rising_edge(clk) then
      if tr_event_i = '1' then
        if addr_idx_input = INPUT_IDX_HI + 1 then
          addr_idx_offset <= addr_idx_offset + BLOCK_SIZE;
        end if;
      end if;
    end if;
  end process compute_offset;

  -- Select one of the Block RAMs' output ('0' => blk_mem_gen_0, '1' => blk_mem_gen_1)
  mux_ctrl_proc : process(tr_addr_i) is
  begin
    if INPUT_IDX_LO <= addr_idx_input and addr_idx_input <= INPUT_IDX_HI then
      -- Must be the input data located between 0x600505BB and 0x600505CB-1
      bram_mux_ctrl <= '1';
    else
      bram_mux_ctrl <= '0';
    end if;
  end process mux_ctrl_proc;

end architecture;
