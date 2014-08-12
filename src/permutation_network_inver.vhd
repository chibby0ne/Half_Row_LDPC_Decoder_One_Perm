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
    signal shift_int: integer range 0 to 2**BW_SHIFT_VEC - 1 := 0;
begin
    shift_int <= to_integer(unsigned(shift));
    output <= input when shift_int = 0 else 
              input(input'high - shift_int downto 0) & input(input'high downto SUBMAT_SIZE - shift_int);
end architecture circuit;
--------------------------------------------------------


