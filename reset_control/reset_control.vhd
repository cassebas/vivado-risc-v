library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;


entity reset_control is
  port (clk       : in std_logic;
        aresetn   : in std_logic;
        cmd_in    : in std_logic_vector(31 downto 0);
        led_out   : out std_logic_vector(7 downto 0);
        cpu_reset : out std_logic);
end reset_control;


architecture behavioral of reset_control is

  -- Assume frequency 100 MHz
  constant CLK_FREQ  : integer := 100_000_000;
  -- Frequency of the LED counter
  constant LED_FREQ  : integer := 10;
  -- Divide the CLK signal to get our wanted LED_FREQ
  constant CLK_DIV   : integer := CLK_FREQ / LED_FREQ;
  -- Compute the number of bits needed to count to CLK_DIV
  constant CNT_LEN   : integer := integer(ceil(log2(real(CLK_DIV+1))));
  signal clk_div_cnt : unsigned(CNT_LEN-1 downto 0);

  signal cmd : std_logic_vector(7 downto 0);
  constant CMD_COUNT : std_logic_vector(7 downto 0) := "00000001";
  constant CMD_BLINK : std_logic_vector(7 downto 0) := "00000010";
  constant CMD_RESET : std_logic_vector(7 downto 0) := "11111111";

  type cmd_state_type is (IDLE, BLINK, COUNT);
  signal state, state_n : cmd_state_type;

  signal led     : std_logic_vector(7 downto 0);
  signal led_cnt : unsigned(7 downto 0);

  signal blink_state : std_logic;

  -- Number of clock periods the reset signal is asserted
  constant RST_CLK_PERIODS : natural := 3;
  -- Number of clock periods the reset signal is to be inhibited
  constant RST_CLK_INHIBIT : natural := 100 - RST_CLK_PERIODS;

begin
  led_cnt_proc: process(clk) is
  begin
    if rising_edge(clk) then
      if aresetn = '0' then
        led_cnt <= (others => '0');
        clk_div_cnt <= (others => '0');
        blink_state <= '0';
        state <= IDLE;
      else
        if clk_div_cnt = CLK_DIV then
          state <= state_n;
          blink_state <= not blink_state;

          if state = COUNT then
            led_cnt <= led_cnt + 1;
          elsif state = BLINK then
            led_cnt <= (others => blink_state);
          else
            -- state is IDLE
            led_cnt <= (others => '0');
          end if;

          clk_div_cnt <= (others => '0');
        else
          clk_div_cnt <= clk_div_cnt + 1;
        end if;
      end if;
    end if;
  end process led_cnt_proc;

  statemachine_proc: process(cmd) is
  begin
    if cmd = CMD_COUNT then
      state_n <= COUNT;
    elsif cmd = CMD_BLINK then
      state_n <= BLINK;
    else
      state_n <= IDLE;
    end if;
  end process statemachine_proc;

  reset_ctrl : process(clk) is
    variable reset_periods : natural;
    variable reset_inhibit : natural;
  begin
    if rising_edge(clk) then
      if aresetn = '0' then
        cpu_reset <= '1';
        reset_periods := 0;
        reset_inhibit := 0;
      else
        if reset_periods > 0 then
          reset_periods := reset_periods - 1;
          cpu_reset <= '0';
        elsif reset_inhibit > 0 then
          reset_inhibit := reset_inhibit - 1;
          cpu_reset <= '1';
        elsif cmd = CMD_RESET then
          -- Reset request
          reset_periods := RST_CLK_PERIODS;
          reset_inhibit := RST_CLK_INHIBIT;
          cpu_reset <= '0';
        end if;
      end if;
    end if;
  end process reset_ctrl;

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

  led <= std_logic_vector(led_cnt);
  led_out <= led;

end Behavioral;
