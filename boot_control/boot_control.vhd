library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;


entity boot_control is
  port (clk          : in std_logic;
        async_resetn : in std_logic;
        cmd_in       : in std_logic_vector(31 downto 0);
        led_out      : out std_logic_vector(7 downto 0);
        cpu_reset    : out std_logic);
end boot_control;


architecture behavioral of boot_control is

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

  signal led     : std_logic_vector(7 downto 0);
  signal led_cnt : unsigned(7 downto 0);

  type cmd_state_type is (IDLE, BLINK, COUNT, RESET_REQ);
  signal state, state_n : cmd_state_type;

  signal blink_state : std_logic;

begin
  led_cnt_proc: process(clk, async_resetn) is
  begin
    if async_resetn = '0' then
      led_cnt <= (others => '0');
      clk_div_cnt <= (others => '0');
      blink_state <= '0';
      state <= IDLE;
      cpu_reset <= '1';
    elsif rising_edge(clk) then
      if clk_div_cnt = CLK_DIV then
        clk_div_cnt <= (others => '0');
        state <= state_n;
        blink_state <= not blink_state;

        if state = COUNT then
          led_cnt <= led_cnt + 1;
        elsif state = BLINK then
          if blink_state = '0' then
            led_cnt <= (others => '1');
          else
            led_cnt <= (others => '0');
          end if;
        elsif state = RESET_REQ then
          cpu_reset <= '0';
        else
          -- state is IDLE
          led_cnt <= (others => '0');
        end if;
      else
        clk_div_cnt <= clk_div_cnt + 1;
      end if;
    end if;
  end process led_cnt_proc;

  statemachine_proc: process(cmd) is
  begin
    if cmd = "00000000" then
      state_n <= IDLE;
    elsif cmd = "00000001" then
      state_n <= COUNT;
    elsif cmd = "00000010" then
      state_n <= BLINK;
    elsif cmd = "11111111" then
      -- cpu reset request
      state_n <= RESET_REQ;
    else
      state_n <= IDLE;
    end if;
  end process statemachine_proc;

  read_cmd: process(clk, async_resetn) is
  begin
    if async_resetn = '0' then
      cmd <= (others => '0');
    elsif rising_edge(clk) then
      cmd <= cmd_in(7 downto 0);
    end if;
  end process read_cmd;

  led <= std_logic_vector(led_cnt);
  led_out <= led;

end Behavioral;
