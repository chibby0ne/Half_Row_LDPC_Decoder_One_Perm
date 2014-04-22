--! 
--! Copyright (C) 2010 - 2011 Creonic GmbH
--!
--! @file: pkg_ieee_802_11ad_param.vhd
--! @brief: Param used for the IEEE 802_11ad
--! @author: Antonio Gutierrez
--! @date: 2014-02-07
--!
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_ieee_802_11ad_param is

    -- constants used for full matrix
    constant R050_ROWS: integer := 8;
    constant R050_COLS: integer := 16;
    constant R062_ROWS: integer := 6;
    constant R062_COLS: integer := 16;
    constant R075_ROWS: integer := 4;
    constant R075_COLS: integer := 16;
    constant R081_ROWS: integer := 3;
    constant R081_COLS: integer := 16;

end package pkg_ieee_802_11ad_param;
