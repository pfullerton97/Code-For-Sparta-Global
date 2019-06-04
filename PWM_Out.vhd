----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.03.2019 13:49:24
-- Design Name: 
-- Module Name: PWM_Out - Implementation
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PWM_Out is
  Port
    (
        clk : in std_logic;
        comp_val : in unsigned(8 downto 0);
        enable : in std_logic;
        mode : in std_logic;
        pwm_out : out std_logic
        
    );
end PWM_Out;

architecture impl of PWM_Out is
type states is (upcount, downcount);
signal StatePc : states := upcount;
signal counterPC : unsigned(7 downto 0) := (others => '0');
signal comparePC : unsigned(7 downto 0) := (others => '0');
signal counter   : unsigned(8 downto 0) := (others => '0');
signal compare   : unsigned(8 downto 0) := (others => '0');
signal pwm_val : std_logic := '1';
begin
pwm_out <= pwm_val;
    process
    begin
        wait until rising_edge(clk);
            if enable = '1' then
                if counter < compare then
                    pwm_val <= '1';
                else
                    pwm_val <= '0';
                end if;
            else
                pwm_val <= '0';
            end if;
    end process;
    process
    begin
        wait until rising_edge(clk);
            if enable = '1' then
                if mode = '0' then
                    if counter > 0 then
                        counter <= counter + 1;
                    else
                        compare <= comp_val;
                        counter <= counter + 1;
                    end if;
                else
                    case statePc is
                        when upcount =>
                            if counter < 511 then
                                counter <= counter + 1;
                            else 
                                statePC <= downcount;
                            end if;
                        when downcount =>
                            if counter > 0 then
                                counter <= counter - 1;
                            else
                                compare <= comp_val;
                                statePC <= upcount;
                            end if;
                    end case;
                end if;
            end if;
    end process;
end impl;
