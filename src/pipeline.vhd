--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: pipeline.vhd
--! @brief: pipeline of LDPC Decoder
--! @author: Antonio Gutierrez
--! @date: 2014-04-30
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
entity pipeline is
--generic declarations
    port (
        clk: in std_logic;
        rst: in std_logic;
        iter: in std_logic_vector(BW_MAX_ITER-1 downto 0);
        out: out std_logic);
end entity pipeline;

