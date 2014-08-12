--------------------------------------------------------
--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: permutation_network.vhd
--! @brief: permutation network inverse design file
--! @author: Antonio Gutierrez
--! @date: 2014-05-01
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
use work.pkg_param_derived.all;
--------------------------------------------------------
entity permutation_network_inver is
    port (
        input: in t_app_messages;
        shift: in t_shift_perm_net; 
        output: out t_app_messages);
end entity permutation_network_inver;
--------------------------------------------------------
architecture circuit of permutation_network_inver is
    type t_array_shift is array (BW_SHIFT_VEC - 1 downto 0) of t_app_messages;
    -- signal shift_int: integer range 0 to 2**BW_SHIFT_VEC - 1 := 0;
begin

    -- shift_int <= to_integer(unsigned(shift));
    -- output <= input when shift_int = 0 else 
    --           input(input'high - shift_int downto 0) & input(input'high downto SUBMAT_SIZE - shift_int);
    --

    process (input, shift)
        variable index: integer range 0 to 2**BW_SHIFT_VEC - 1;
        variable shifted_input: t_array_shift;
    begin

        for i in 0 to BW_SHIFT_VEC - 1 loop                                         -- for all stages (0 to 5)
            if (shift(i) = '1') then                                                -- if that bit of shift is '1' we shift by 2**i to the left
                for j in 0 to SUBMAT_SIZE - 1 loop                                  -- each bit of input
                    if (i = 0) then                                                 -- first time is done from input
                        shifted_input(i)(j) := input((j - 2**i) mod SUBMAT_SIZE);
                    else
                        shifted_input(i)(j) := shifted_input(i - 1)((j - 2**i) mod SUBMAT_SIZE);
                    end if;
                end loop;
            else                                                                    -- if not '1' we connect it straight
                for j in 0 to SUBMAT_SIZE - 1 loop                                  -- for each bit of input
                    if (i = 0) then
                        shifted_input(i)(j) := input(j);                             
                    else
                        shifted_input(i)(j) := shifted_input(i - 1)(j);
                    end if;
                end loop;
            end if;
        end loop;
        output <= shifted_input(5);

    end process;

end architecture circuit;
--------------------------------------------------------


