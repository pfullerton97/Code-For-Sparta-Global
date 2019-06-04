----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.03.2019 11:57:31
-- Design Name: 
-- Module Name: IIR_Filter - Behavioral
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
use IEEE.numeric_std.ALL;

entity IIR_2 is
    Port 
    ( 
        clk : in std_logic;
        start : in std_logic;
        sample : in signed(12 downto 0);
        n0 : in signed (24 downto 0);
        n1 : in signed (24 downto 0);
        n2 : in signed (24 downto 0);
        gain : in signed (24 downto 0);
        d0 : in signed (24 downto 0);
        d1 : in signed (24 downto 0);
        overflow : out std_logic;
        underflow : out std_logic;
        result : out signed(12 downto 0)
    );
end IIR_2;
    
architecture impl of IIR_2 is 
type states is (idle, init, step_1, step_2, step_3,
                step_4, step_5, step_6, step_7, step_8,
                step_9, step_10, step_11, step_12);
signal current_state    : states := idle;
signal x0               : signed(12 downto 0)   := (others => '0'); -- new sample
signal x1               : signed(12 downto 0)   := (others => '0'); -- feedforward value n-1
signal x2               : signed(12 downto 0)   := (others => '0'); -- feedforward value n-2
signal y0               : signed(12 downto 0)   := (others => '0'); -- new ouput
signal y1               : signed(12 downto 0)   := (others => '0'); -- feedback value n-1 
signal y2               : signed(12 downto 0)   := (others => '0'); -- feedback value n-2
signal n0_sig           : signed(24 downto 0)   := (others => '0'); -- numerator co-efficient 1
signal n1_sig           : signed(24 downto 0)   := (others => '0'); -- numerator co-efficient 2
signal n2_sig           : signed(24 downto 0)   := (others => '0'); -- numerator co-efficient 2
signal k_sig            : signed(24 downto 0)   := (others => '0'); -- gain
signal d1_sig           : signed(24 downto 0)   := (others => '0'); -- denominator co-efficient 1
signal d2_sig           : signed(24 downto 0)   := (others => '0'); -- denominator co-efficient 2
signal mult_result      : signed(37 downto 0)   := (others => '0');
signal shift_result     : signed(15 downto 0)   := (others => '0');
signal mult_result3     : signed(37 downto 0)   := (others => '0');
signal accumulator      : signed(16 downto 0)   := (others => '0');
signal ff_mult_result   : signed(41 downto 0)   := (others => '0');
signal ff_result        : signed(16 downto 0)   := (others => '0');
signal fb_result        : signed(16 downto 0)   := (others => '0');
signal y0_temp          : signed(19 downto 0)   := (others => '0');
signal mul_val1         : signed(24 downto 0)   := (others => '0');
signal mul_val2         : signed(12 downto 0)   := (others => '0');
signal mul_result       : signed(37 downto 0)   := (others => '0');
signal mul_reset        : std_logic             := '0';
signal fb_stage         : std_logic             := '0';


begin
result <= y0;
process
begin
    wait until rising_edge(clk);
        case current_state is 
            when idle =>
                if start = '1' then
                    current_state <= init;
                else
                    current_state <= current_state;
                end if;
            when init =>
                x2 <= x1;
                x1 <= x0;
                x0 <= sample;
                y2 <= y1;
                y1 <= y0;
                n0_sig <= n0;
                n1_sig <= n1;
                n2_sig <= n2;
                k_sig <= gain;
                d1_sig <= d0;
                d2_sig <= d1;
                mul_reset <= '0';
                fb_stage <= '0';
                current_state <= step_1;
            when step_1 =>
                mul_val1 <= n0_sig;
                mul_val2 <= x0;
                current_state <= step_2;
            when step_2 =>
                mul_val1 <= n1_sig;
                mul_val2 <= x1;
                current_state <= step_3;
            when step_3 =>
                mul_val1 <= n2_sig;
                mul_val2 <= x2;
                current_state <= step_4;
            when step_4 =>
                mul_val1 <= (others => '0');
                mul_val2 <= (others => '0');
                current_state <= step_5;
            when step_5 =>
                ff_result <= accumulator;
                mul_reset <= '1';
                fb_stage <= '1';
                current_state <= step_6;
            when step_6 =>
                mul_val1 <= d1_sig;
                mul_val2 <= y1;
                mul_reset <= '0';
                current_state <= step_7;
            when step_7 =>
                mul_val1 <= d2_sig;
                mul_val2 <= y2;
                current_state <= step_8;
            when step_8 =>
                mul_val1 <= (others => '0');
                mul_val2 <= (others => '0');
                current_state <= step_9;
            when step_9 =>
                fb_result <= accumulator;
                mul_reset <= '1';
                ff_mult_result <= k_sig*ff_result;
                current_state <= step_10;
            when step_10 =>
                y0_temp <= ff_mult_result(41 downto 22);
                current_state <= step_11;
            when step_11 =>
                y0_temp <= y0_temp - fb_result;
                current_state <= step_12;
            when step_12 =>
                if (y0_temp < 4096) and (y0_temp >= 0) then
                    y0 <= resize(y0_temp,13);
                    overflow <= '0';
                    underflow <= '0';
                elsif y0_temp >= 4096 then
                    y0 <= to_signed(4095,13);
                    overflow <= '1';
                    underflow <= '0';
                elsif y0_temp < 0 then
                    y0 <= to_signed(0,13);
                    overflow <= '0';
                    underflow <= '1';
                end if;
                current_state <= idle;
        end case;
end process;

process
begin
    wait until rising_edge(clk);
        if mul_reset = '0' then
            mul_result <= mul_val1*mul_val2;
            if fb_stage = '0' then
                accumulator <= accumulator + mul_result(37 downto 22);
            else
                accumulator <= accumulator - mul_result(37 downto 22);
            end if;
        else
            accumulator <= (others => '0');
        end if;
end process;
end impl;
