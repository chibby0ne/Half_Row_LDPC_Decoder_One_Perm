--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: top_level_wrapper.vhd
--! @brief: top level wrapper required by synthesis and P&R tools
--! @author: Antonio Gutierrez
--! @date: 2014-08-09
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_param.all;
use work.pkg_components.all;
--------------------------------------------------------
entity top_level_wrapper is
    port (
    -- inputs
        clk: in std_logic;
        rst: in std_logic;
        code_rate: in std_logic_vector(1 downto 0);                 -- 4 possible code rates log2 4 = 2
        input: in std_logic_vector((MAX_CHV / 2) * BW_APP - 1 downto 0);  -- 672 signals of BW_APP bits each
    -- outputs
        new_codeword: out std_logic;
        valid_output: out std_logic;
        output: out std_logic_vector(MAX_CHV - 1 downto 0));            -- 672 signals of 1 bit each
end entity top_level_wrapper;
--------------------------------------------------------
architecture circuit of top_level_wrapper is

    signal code_rate_map: t_code_rate;
    signal input_map: t_app_message_half_codeword;
    signal output_map: t_hard_decision_full_codeword;


begin

    
    --------------------------------------------------------------------------------------
    -- mapping of signals
    --------------------------------------------------------------------------------------

    -- code_rate
    code_rate_map <= R050 when code_rate = "00" else 
                     R062 when code_rate = "01" else
                     R075 when code_rate = "10" else 
                     R081;


    -- input
    gen_input: for i in 0 to MAX_CHV / 2 - 1 generate
        gen_input_detail: for j in 0 to BW_APP - 1 generate
            input_map(i / SUBMAT_SIZE)(i mod SUBMAT_SIZE)(j) <= input(i * BW_APP + j);
        end generate gen_input_detail;
    end generate gen_input;

    
    -- output
    gen_output: for i in 0 to MAX_CHV - 1 generate
        output(i) <= output_map(i / SUBMAT_SIZE)(i mod SUBMAT_SIZE);
    end generate gen_output;
    

    --------------------------------------------------------------------------------------
    -- top level module instantiation
    --------------------------------------------------------------------------------------

    top_level_ins: top_level port map (
        clk => clk,
        rst => rst,
        code_rate => code_rate_map,
        input => input_map,

        new_codeword => new_codeword,
        valid_output => valid_output,
        output => output_map
    );
    
    
end architecture circuit;
--------------------------------------------------------
