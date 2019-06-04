library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_level is

     Port
     (
        clk         : in  std_logic;
        pmod_miso   : in  std_logic;
        aud_pwm     : out std_logic;
        aud_sd      : out std_logic;
        pmod_ss     : out std_logic;
        sw     : in  std_logic_vector (1 downto 0);
        pmod_sclk   : out std_logic;
        ck_io0      : out std_logic;
        ck_io1      : out std_logic;
        btn        : in std_logic_vector (3 downto 0);
        led    : out std_logic_vector (3 downto 0)
              
     );

end;

architecture behav of top_level is
    constant inc_val    :   unsigned(23 downto 0)           := (18 => '1', others => '0');
    type    pmod_states is (start, waiting, done);
    type    gain_states is (S1, S2, S3, S4, S5);
    type    filter_states is (idle, strip_bias, apply_gain, shift);
    signal  filter_state:   filter_states                   := idle;
    signal  gain_state  :   gain_states                     := S1;
    signal  pmod_state  :   pmod_states                     := start;
    signal  pmod_start  :   std_logic                       := '0';
    signal  pmod_done   :   std_logic                       := '0';
    signal  pmod_data   :   std_logic_vector(11 downto 0)   := (others => '0');
    signal  rst         :   std_logic                       := '0';
    signal  sample      :   unsigned(11 downto 0)           :=  (others => '0');
    signal  pwm_out     :   std_logic                       := '0';
    signal  pwm_sd      :   std_logic                       := '1';
    signal  filter_done :   std_logic                       := '0';
    signal  pwm_comp    :   unsigned(8 downto 0)            := (others => '0');
    signal  pwm_mode    :   std_logic                       := '0';
    signal  enable      :   std_logic                       := '1';
    signal  filter_start:   std_logic                       := '0';
    signal  new_sample  :   std_logic                       := '0';
    signal  gain        :   unsigned(23 downto 0)             := (23 => '1', others => '0');
    signal  mul_res     :   unsigned(35 downto 0)           := (others => '0');
    signal  final_result:   unsigned(12 downto 0)           := (others => '0');
    signal  filter_samp :   unsigned(11 downto 0)           := (others => '1');
    signal  counter     :   unsigned(25 downto 0)           := (others => '0');
begin

aud_pwm <= pwm_out;
aud_sd  <= pwm_sd;
ck_io0  <= pwm_out;
--led(0)  <= btn(0);
--led(1)  <= btn(1);

    pmod_mic: entity WORK.pmodmicrefcomp
    port map
    (
        CLK     =>  clk,
        RST     =>  rst,         
        SDATA   =>  pmod_miso,   --input
        SCLK    =>  pmod_sclk,   --output
        nCS     =>  pmod_ss,     --output
        DATA    =>  pmod_data,   --output
        START   =>  pmod_start,  --input
        DONE    =>  pmod_done    --output
    );
    
    pwm_wave:entity WORK.PWM_Out
    port map
    (
        clk => clk,
        comp_val => pwm_comp,
        enable => enable,
        pwm_out => pwm_out,
        mode => pwm_mode
    );

      process
    begin
        wait until rising_edge(clk);
            case pmod_state is
                when start =>
                    pmod_start <= '1';
                    --filter_start <= '0';
                    if pmod_done = '0' then
                        --new_sample <= '0';
                        pmod_state <= waiting;
                    else
                        pmod_state <= pmod_state;
                    end if;
                    new_sample <= '0';
                when waiting =>
                    pmod_start <= '0';
                        if pmod_done = '1' then
                            pmod_state <= done;
                        else
                            pmod_state <= waiting;
                        end if;
                when done =>
                    sample <= unsigned(pmod_data);
                    new_sample <= '1';
                    --filter_start <= '1';
                    pmod_state <= start;
             end case;
    end process;
    process
    begin
        wait until rising_edge(clk);
            case filter_state is
                when idle =>
                    if new_sample = '1' then
                        filter_state <= strip_bias;
                    else 
                        filter_state <= filter_state;
                    end if;
                when strip_bias =>
                    filter_samp <= sample;
                    filter_state <= apply_gain;
                when apply_gain =>
                    mul_res <= filter_samp*gain;
                    filter_state <= shift;
                when shift =>
                    final_result <= mul_res(35 downto 23);
                    filter_state <= idle;
            end case;
    end process;
    
    process
    begin
        wait until rising_edge(clk);
            if sw = "00" then
                pwm_comp <= unsigned(pmod_data(11 downto 3));
                led(3 downto 2) <= "00";
            elsif sw = "01" then
                pwm_comp <= final_result(11 downto 3);
            elsif sw = "10" then
                pwm_comp <= final_result(11 downto 3);
            else
                pwm_comp <= unsigned(pmod_data(11 downto 3));
            end if;
    end process;
    process
    begin
    wait until rising_edge(clk);
        if btn(0) = '1' and btn(1) = '0' then
            if counter(25) = '1' then
                led(0) <= '1';
                if gain(23) = '0' then
                    gain <= gain + inc_val;
                end if;
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
            led(1) <= '0';
        elsif btn(1) = '1' and btn(0) = '0' then
            if counter(25) = '1' then
                led(1) <= '1';
                if gain > inc_val then
                    gain <= gain - inc_val;
                end if;
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
            led(0) <= '0';
        elsif btn(1) = '1' and btn(0) = '1' then
            led(0) <= '0';
            led(1) <= '0';
        else
            led(0) <= '0';
            led(1) <= '0';
            counter <= (others => '0');
        end if;
    end process;
end;
