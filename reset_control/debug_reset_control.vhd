library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debug_reset_control is
  port (clk             : in std_logic;
        cpu_reset_n     : in std_logic;
        logic_set       : in std_logic;
        logic_reset     : in std_logic;
        dbg_cpu_reset_n : out std_logic;
        dbg_logic_set   : out std_logic;
        dbg_logic_reset : out std_logic);
end entity debug_reset_control;


architecture behavioural of debug_reset_control is

  -- The signals must be able to count at least to 10 (4 bits)
  constant MAX_COUNT : positive := 10;

  signal cnt_cpu_reset_n : unsigned(3 downto 0) := (others => '0');
  signal cnt_logic_set   : unsigned(3 downto 0) := (others => '0');
  signal cnt_logic_reset : unsigned(3 downto 0) := (others => '0');

begin
  dbg_cpu_reset_n <= '0' when cnt_cpu_reset_n > 0 else
                     '1';

  dbg_logic_set <= '1' when cnt_logic_set > 0 else
                   '0';

  dbg_logic_reset <= '1' when cnt_logic_reset > 0 else
                     '0';

  count_cpu_reset_n : process(clk) is
  begin
    if rising_edge(clk) then
      if cnt_cpu_reset_n > 0 then
        -- The cpu_reset_n has been asserted
        if cnt_cpu_reset_n < MAX_COUNT then
          cnt_cpu_reset_n <= cnt_cpu_reset_n + 1;
        else
          cnt_cpu_reset_n <= (others => '0');
        end if;
      elsif cpu_reset_n = '0' then
        cnt_cpu_reset_n <= (0 => '1', others => '0');
      end if;
    end if;
  end process count_cpu_reset_n;

  count_logic_set : process(clk) is
  begin
    if rising_edge(clk) then
      if cnt_logic_set > 0 then
        -- The cpu_reset_n has been asserted
        if cnt_logic_set < MAX_COUNT then
          cnt_logic_set <= cnt_logic_set + 1;
        else
          cnt_logic_set <= (others => '0');
        end if;
      elsif logic_set = '1' then
        cnt_logic_set <= (0 => '1', others => '0');
      end if;
    end if;
  end process count_logic_set;

  count_logic_reset : process(clk) is
  begin
    if rising_edge(clk) then
      if cnt_logic_reset > 0 then
        -- The cpu_reset_n has been asserted
        if cnt_logic_reset < MAX_COUNT then
          cnt_logic_reset <= cnt_logic_reset + 1;
        else
          cnt_logic_reset <= (others => '0');
        end if;
      elsif logic_reset = '1' then
        cnt_logic_reset <= (0 => '1', others => '0');
      end if;
    end if;
  end process count_logic_reset;

end architecture behavioural;
