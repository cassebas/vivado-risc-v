library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity boot_device_addrtranslator is
  generic (BRAM_DATA_WIDTH  : integer := 32;
           BRAM_ADDR_WIDTH  : integer := 16;
           BRAM_WEA_WIDTH   : integer := 4;
           ARRAYS_PER_BLOCK : integer := 16);

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
        inputdata_mux_ctrl_o : out std_logic;
        -- These outputs come from the rangextractor, they are dynamically set
        array_start_i        : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        array_end_i          : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        array_size_i         : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        -- These signals come from reset_control
        logic_set_ev_i       : in std_logic;
        logic_rst_ev_i       : in std_logic);
end entity boot_device_addrtranslator;


architecture structural of boot_device_addrtranslator is

  signal tr_addr  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_addr : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal input_addr_offset : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal input_addr_offset_nxt : unsigned(BRAM_ADDR_WIDTH-1 downto 0);

  signal array_start : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal array_end   : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal array_size  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal logic_set : std_logic := '0';

  signal reset_active : std_logic := '0';
  signal reset_cnt : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

  signal appdata_mux_ctrl   : std_logic := '0';
  signal inputdata_mux_ctrl : std_logic := '0';

  signal max_offset  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

begin
  -- Simple passthrough for the blockram containing bytes representing
  -- the application.
  tr_app_wea_o <= tr_wea_i;
  tr_app_addr_o <= tr_addr_i;
  tr_app_data_o <= tr_data_i;

  -- The input address might need a changes since the input values for the
  -- application are taken from another blockram at increasing addresses.
  tr_input_wea_o <= tr_wea_i;
  tr_input_addr_o <= std_logic_vector(input_addr);
  tr_input_data_o <= tr_data_i;


  -- Convert the input address requested to unsigned
  tr_addr <= unsigned(tr_addr_i);

  -- Compute the input address for the blockram containing input values.
  input_addr <= tr_addr - array_start + input_addr_offset;
  input_addr_offset_nxt <= input_addr_offset + array_size;

  appdata_mux_ctrl_o   <= appdata_mux_ctrl;
  inputdata_mux_ctrl_o <= inputdata_mux_ctrl;

  compute_offset : process (clk) is
  begin
    if rising_edge(clk) then
      if logic_set_ev_i = '1' then
        reset_cnt <= (others => '0');
        inputdata_mux_ctrl <= not inputdata_mux_ctrl;
      elsif cpu_reset_n = '0' then
        -- Only increase offset upon a *new* reset event
        if reset_active = '0' then
          if logic_set = '1' then
            if reset_cnt < ARRAYS_PER_BLOCK then
              reset_cnt <= reset_cnt + 1;
              if reset_cnt > 0 then
                -- At the very first reset the offset should not be incremented
                input_addr_offset <= input_addr_offset_nxt;
              end if;
            else
              -- reset_cnt == ARRAYS_PER_BLOCK, reset to one
              reset_cnt <= (0 => '1', others => '0');
              input_addr_offset <= (others => '0');
              inputdata_mux_ctrl <= not inputdata_mux_ctrl;
            end if;
          end if;
          reset_active <= '1';
        end if;
      else
        reset_active <= '0';
      end if;
    end if;
  end process compute_offset;

  logic_set_reset : process (clk) is
  begin
    if rising_edge(clk) then
      if logic_set_ev_i = '1' then
        logic_set <= '1';
        -- Convert the array configuration data to unsigned values
        array_start <= unsigned(array_start_i);
        array_end   <= unsigned(array_end_i);
        array_size  <= unsigned(array_size_i);
      elsif logic_rst_ev_i = '1' then
        logic_set <= '0';
        array_start <= (others => '0');
        array_end   <= (others => '0');
        array_size  <= (others => '0');
      end if;
    end if;
  end process logic_set_reset;

  -- Select one of the Block RAMs' output
  -- ('0' => blk_mem_app_0/1, '1' => blk_mem_data_0/1)
  mux_ctrl_proc : process(array_start, array_end, logic_set, tr_addr) is
  begin
    if logic_set /= '1' then
      appdata_mux_ctrl <= '0';
    else
      if array_start <= tr_addr and tr_addr <= array_end then
        appdata_mux_ctrl <= '1';
      else
        appdata_mux_ctrl <= '0';
      end if;
    end if;
  end process mux_ctrl_proc;

end architecture;
