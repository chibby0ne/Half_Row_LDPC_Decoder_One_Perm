--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: output_module.vhd
--! @brief: output module used for ordering the output of app information into row order
--! @author: Antonio Gutierrez
--! @date: 2014-06-23
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_ieee_802_11ad_matrix.all;
use work.pkg_param.all;
use work.pkg_types.all;
--------------------------------------------------------
entity output_module is
--generic declarations
    port (
        rst: in std_logic;
        clk: in std_logic;
        finish_iter: in std_logic;
        code_rate: in t_code_rate;
        input: in t_hard_decision_half_codeword;
        output: out t_hard_decision_full_codeword);
end entity output_module;
--------------------------------------------------------
architecture circuit of output_module is

    type t_output_vector is array (1 downto 0) of t_hard_decision_half_codeword;
    signal shift: t_array16;
    
begin

    
    --------------------------------------------------------------------------------------
    -- combinational part
    -- select shifting info depending on coder ate selected
    --------------------------------------------------------------------------------------

    shift <= IEEE_802_11AD_P42_N672_R050_SHIFTING_INFO when code_rate = R050 else 
             IEEE_802_11AD_P42_N672_R062_SHIFTING_INFO when code_rate = R062 else
             IEEE_802_11AD_P42_N672_R075_SHIFTING_INFO when code_rate = R075 else 
             IEEE_802_11AD_P42_N672_R081_SHIFTING_INFO;  

    --------------------------------------------------------------------------------------
    -- sequential part:
    -- storing both halves and arranging output vector according to shifting info
    --------------------------------------------------------------------------------------

    process (clk, rst)
        variable count: integer range 0 to 1 := 0;
        variable val: integer range 0 to SUBMAT_SIZE - 1 := 0;      
        variable base: integer range 0 to MAX_CHV - 1 := 0;         -- vng group
        variable input_reg: t_output_vector;
        
    begin
        if (rst = '1') then
            output <= (others => (others => '0'));
        elsif (clk'event and clk = '1') then
            if (finish_iter = '1') then
                if (count = 0) then
                    input_reg(1) := input;

                    count := count + 1;
                else
                    input_reg(0) := input;
                    count := 0;

                    
                    -- check if this is correct order
                    -- i'm going to start decoding from the MSB half
                    -- we need to shift the leftmost shift in the matrix to the MS group APP (meaning app 15)

                    for i in 1 downto 0 loop                            -- for all half
                        for j in CFU_PAR_LEVEL - 1 downto 0 loop        -- for all APPs
                            for k in SUBMAT_SIZE - 1 downto 0 loop      -- for all 42 elements 
                                base := i * CFU_PAR_LEVEL + j;
                                val := (k - shift((2 * CFU_PAR_LEVEL - 1) - base)) mod SUBMAT_SIZE;     -- shift starts from 0 to 16 meaning that the leftmost is 0 that's why this index is so complicated
                                output(base)(k) <= input_reg(i)(j)(val);
                            end loop;
                        end loop;
                    end loop;

                end if;
            end if;
        end if;
    end process;

end architecture circuit;
