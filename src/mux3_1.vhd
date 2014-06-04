--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: mux3_1.vhd
--! @brief: mux 3 to 1 used at output of app
--! @author: Antonio Gutierrez
--! @date: 2014-05-30
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_support.all;
use work.pkg_types.all;
--------------------------------------------------------
entity mux3_1 is
--generic declarations
    port (
        input0: in std_logic_vector(CFU_PAR_LEVEL - 1 downto 0); 
        input1: in std_logic_vector(CFU_PAR_LEVEL - 1 downto 0); 
        input2: in std_logic_vector(CFU_PAR_LEVEL - 1 downto 0); 
        sel: in std_logic_vector(1 downto 0);
        output: in std_logic_vector(CFU_PAR_LEVEL - 1 downto 0));
end entity mux3_1;
--------------------------------------------------------
architecture circuit of mux3_1 is
    signal sel_int: integer range 0 to 3;
begin
    sel_int <= to_integer(unsigned(sel));
    ouput <= input0 when sel_int = 0 else 
         input1 when sel_int = 1 else
         input2 when sel_int = 2;
end architecture circuit;
--------------------------------------------------------


