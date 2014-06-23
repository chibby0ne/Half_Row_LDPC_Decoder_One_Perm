--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: top_level_tb.vhd
--! @brief: testbench for top level
--! @author: Antonio Gutierrez
--! @date: 2014-06-20
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_components.all;
--------------------------------------------------------
entity top_level_tb is
    generic (PERIOD: time := 40 ns);
end entity top_level_tb;
--------------------------------------------------------
architecture circuit of top_level_tb is

    
    --------------------------------------------------------------------------------------
    -- component declaration
    --------------------------------------------------------------------------------------
    component top_level is
        port (
                 clk: in std_logic;
                 rst: in std_logic;
                 code_rate: in t_code_rate;
                 input: in t_message_app_full_codeword;

        -- outputs
                 valid_output: out std_logic;
                 output: out t_message_app_full_codeword);
    end component top_level;

    
    --------------------------------------------------------------------------------------
    -- signal declaration 
    --------------------------------------------------------------------------------------
    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';
    signal code_rate_tb: t_code_rate;
    signal input_tb: t_message_app_full_codeword;
    signal valid_output_tb: std_logic := '0';
    signal output_tb: t_message_app_full_codeword;
    file f: text open read_mode is "test_file_input.txt";
    file f_out: text open read_mode is "test_file_output.txt";
    
    
begin

    --------------------------------------------------------------------------------------
    -- component instantiation
    --------------------------------------------------------------------------------------
    dut: top_level port map (
        clk => clk_tb,
        rst => rst_tb,
        code_rate => code_rate_tb,
        input => input_tb,  
        valid_output => valid_output_tb,
        output => output_tb
    );

    
    --------------------------------------------------------------------------------------
    -- stimuli generation
    --------------------------------------------------------------------------------------

    
    -- clk
    clk_tb <= not clk_tb after PERIOD / 2;
    
    
    -- rst
    rst_tb <= '0';

    
    -- code rate
    code_rate_tb <= R050;

    
    -- input
    process
        variable l: line;
        variable val: integer range := 0;
        
        
    begin
        if (not endfile(f)) then
            for i in  loop
                --sequential statements
            end loop;
        end if;
    end process;


end architecture circuit;
