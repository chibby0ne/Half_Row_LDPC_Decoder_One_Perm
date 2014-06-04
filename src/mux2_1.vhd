--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: mux2_1.vhd
--! @brief: mux 2 to 1
--! @author: Antonio Gutierrez
--! @date: 2014-05-30
--!
--!
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_param.all;
--------------------------------------------------------
entity mux2_1 is
--generic declarations
    port (
        input0: in std_logic_vector(SUBMAT_SIZE - 1 downto 0);
        input1: in std_logic_vector(SUBMAT_SIZE - 1 downto 0);
        sel: in std_logic;
        output: out std_logic_vector(SUBMAT_SIZE - 1 downto 0));
end entity mux2_1;
--------------------------------------------------------
architecture circuit of mux2_1 is
begin
    output <= input0 when sel = '0' else input1;
end architecture circuit;
--------------------------------------------------------
