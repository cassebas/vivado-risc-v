library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;


entity reset_control is
  port (clk         : in std_logic;
        aresetn     : in std_logic;
        cmd_in      : in std_logic_vector(31 downto 0);
        cpu_reset_n : out std_logic;
        logic_set   : out std_logic;
        logic_reset : out std_logic);
end reset_control;


architecture behavioral of reset_control is

  signal cmd : std_logic_vector(7 downto 0);
  constant CMD_RESET       : std_logic_vector(7 downto 0) := "11111111"; -- 0xFF
  constant CMD_LOGIC_SET   : std_logic_vector(7 downto 0) := "10011001"; -- 0x99
  constant CMD_LOGIC_RESET : std_logic_vector(7 downto 0) := "11001100"; -- 0xCC

  signal cpu_reset_n_ff : std_logic := '1';

  signal logic_set_ff : std_logic := '0';
  signal logic_rst_ff : std_logic := '0';

  signal logic_rst_ev : std_logic := '0';
  signal logic_set_ev : std_logic := '0';

begin
  reset_ctrl : process(clk) is
  begin
    if rising_edge(clk) then
      if aresetn = '0' then
        cpu_reset_n_ff <= '1';
        logic_set_ff <= '0';
        logic_rst_ff <= '0';
        logic_set_ev <= '0';
        logic_rst_ev <= '0';
      else
        if cmd = CMD_RESET then
          cpu_reset_n_ff <= '0';
        elsif cmd = CMD_LOGIC_SET then
          if logic_set_ev /= '1' then
            logic_set_ff <= '1';
            logic_set_ev <= '1';
          else
            logic_set_ff <= '0';
          end if;
        elsif cmd = CMD_LOGIC_RESET then
          if logic_rst_ev /= '1' then
            logic_rst_ff <= '1';
            logic_rst_ev <= '1';
          else
            logic_rst_ff <= '0';
          end if;
        end if;
      end if;
    end if;
  end process reset_ctrl;

  cpu_reset_n <= cpu_reset_n_ff;
  logic_set <= logic_set_ff;
  logic_reset <= logic_rst_ff;

  read_cmd: process(clk) is
  begin
    if rising_edge(clk) then
      if aresetn = '0' then
        cmd <= (others => '0');
      else
        cmd <= cmd_in(7 downto 0);
      end if;
    end if;
  end process read_cmd;

end Behavioral;
