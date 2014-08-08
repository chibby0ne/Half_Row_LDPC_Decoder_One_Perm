--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: output_module_two_perm.vhd
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
entity output_module_two_perm is
--generic declarations
    port (
        rst: in std_logic;
        clk: in std_logic;
        finish_iter: in std_logic;
        input: in t_hard_decision_half_codeword;
        output: out t_hard_decision_full_codeword);
end entity output_module_two_perm;
--------------------------------------------------------
architecture circuit of output_module_two_perm is

    type t_output_vector is array (1 downto 0) of t_hard_decision_half_codeword;
    signal shift: t_array16;

    signal input_reg_sig: t_output_vector;              -- for debugging purpose
    
    
begin

    
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
                    input_reg(0) := input;
                    input_reg_sig(0) <= input;
                    count := count + 1;
                else
                    input_reg(1) := input;
                    input_reg_sig(1) <= input;
                    count := 0;

                    
                    -- check if this is correct order
                    -- i'm going to start decoding from the MSB half
                    -- we need to shift the leftmost shift in the matrix to the MS group APP (meaning app 15)

                    for i in 0 to 1 loop
                        for j in 0 to CFU_PAR_LEVEL - 1 loop
                            for k in 0 to SUBMAT_SIZE - 1 loop
                                base := i * CFU_PAR_LEVEL + j;
                                output(base)(k) <= input_reg(i)(j)(k);
                            end loop;
                        end loop;
                    end loop;

                end if;
            end if;
        end if;
    end process;

end architecture circuit;
