--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: mux2_1_msg_ram.vhd
--! @brief: mux 2 to 1 for t_cn_messages types (used inside CNB)
--! @author: Antonio Gutierrez
--! @date: 2014-08-05
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
--------------------------------------------------------
entity mux2_1_msg_ram is
    port (
        input0: in signed(BW_EXTR - 1 downto 0);
        input1: in signed(BW_EXTR - 1 downto 0);
        sel: in std_logic;
        output: out signed(BW_EXTR - 1 downto 0
    ));
end entity mux2_1_msg_ram;
--------------------------------------------------------
architecture circuit of mux2_1_msg_ram is
begin
    output <= input0 when sel = '0' else input1;
end architecture circuit;
--------------------------------------------------------
