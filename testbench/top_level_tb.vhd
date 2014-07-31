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
use std.textio.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_components.all;
use work.pkg_param.all;
--------------------------------------------------------
entity top_level_tb is
    generic (PERIOD: time := 40 ns;
            PD: time := 3 ns);
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
                 input: in t_app_message_full_codeword;

        -- outputs
                 valid_output: out std_logic;
                 output: out t_hard_decision_full_codeword);
    end component top_level;

    
    --------------------------------------------------------------------------------------
    -- signal declaration 
    --------------------------------------------------------------------------------------
    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';
    signal code_rate_tb: t_code_rate;
    signal input_tb: t_app_message_full_codeword;
    signal valid_output_tb: std_logic := '0';
    signal output_tb: t_hard_decision_full_codeword;
    file fin: text open read_mode is "input_decoder_oneword.txt";
    file fout: text open read_mode is "output_decoder_oneword.txt";
    
    
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
        variable val: integer;
    begin
        if (not endfile(fin)) then
            for i in 0 to 2 * CFU_PAR_LEVEL - 1 loop
                for j in 0 to SUBMAT_SIZE - 1 loop
                    readline(fin, l);
                    read(l, val);
                    input_tb(i)(j) <= to_signed(val, BW_APP);
                end loop;
            end loop;
        else
            wait for 360 * PERIOD;
            assert false
            report "end of inputs"
            severity failure;
        end if;
    end process;

    
    --------------------------------------------------------------------------------------
    -- output comparison
    --------------------------------------------------------------------------------------

    -- process
    --     variable l: line;
    --     variable val: integer := 0;
    -- begin
    --     if (not endfile(fout)) then
    --         wait for TIME;
    --         for i in MAX_CHV - 1 downto 0 loop
    --             readline(fout, l);
    --             read(l, val);
    --             assert output_tb(i) = std_logic(val)
    --             report "error. output( " & integer'image(i) & ") should be = " & integer'image(val) & "but is = " & integer'image(to_integer(output(i)))
    --             severity failure;
    --         end loop;
    --     else
    --         assert false
    --         report "no errors"
    --         severity failure;
    --     end if;
    -- end process;
end architecture circuit;
