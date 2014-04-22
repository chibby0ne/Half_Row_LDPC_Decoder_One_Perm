--!
--! Copyright (C) 2010 - 2011 Creonic GmbH
--!
--! @file   pkg_param_derived.vhd
--! @brief  Derived parameters from the pkg_param.vhd
--! @author Philipp Schläfer
--! @date   2010/10/14
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_support_global.all;
use work.pkg_param.all;


package pkg_param_derived is

	-- Number of instantiated VFUs 16 x 42 =  672
	constant NUM_VFU         : natural := CFU_PAR_LEVEL * SUBMAT_SIZE;

	-- Number of submatrices 16
	constant NUM_SUBMAT      : natural := (MAX_CHV / SUBMAT_SIZE);

	-- Number of cfu submatrices 168/ 42 = 4
	constant NUM_SUBMAT_CFU  : natural := (NUM_CFU / SUBMAT_SIZE);

	-- Number of vfu submatrices  = 16
	constant NUM_SUBMAT_VFU  : natural := (NUM_VFU / SUBMAT_SIZE);

	-- Number of submatrices in a block = 64
	constant NUM_SUBMATS       : natural := CFU_PAR_LEVEL * VFU_PAR_LEVEL;

	-- Number of bits required to represent the number of channel values. = 10
	constant BW_MAX_CHV      : natural := no_bits_natural(MAX_CHV);

	-- Number of bits generated as output per cycle = 672
	constant OUTPUT_BITS     : natural := MAX_CHV;

	-- Bits required to represent the amount of VFUs = 10
	constant BW_NUM_VFU      : natural := no_bits_natural(NUM_VFU - 1);

	-- Number of bits to represent the CFU_PAR_LEVEL =  4
	constant BW_CFU_PAR_LEVEL  : natural := no_bits_natural(CFU_PAR_LEVEL - 1);

	-- Number of bits to represent the VFU_PAR_LEVEL =  2
	constant BW_VFU_PAR_LEVEL  : natural := no_bits_natural(VFU_PAR_LEVEL - 1);

	-- Bitwidth needed to represent the maximal shift value 
	constant BW_SHIFT_VEC      : natural := no_bits_natural(SUBMAT_SIZE - 1);
	-- Number of bits needed to represent the max number of iterations
	constant BW_MAX_ITER       : natural := no_bits_natural(MAX_ITER);

    -- Number of bits needed to address the number of CNGs for R=0.5
    constant BW_APP_MESSAGES_R050: natural := no_bits_natural(MAX_CHECK_DEGREE_R050 - 1);

    -- Number of bits needed to address the number of CNGs for R=0.62
    constant BW_APP_MESSAGES_R062: natural := no_bits_natural(MAX_CHECK_DEGREE_R062 - 1);

    -- Number of bits needed to address the number of CNGs for R=0.75
    constant BW_APP_MESSAGES_R075: natural := no_bits_natural(MAX_CHECK_DEGREE_R075 - 1);

    -- Number of bits needed to address the number of CNGs for R=0.5
    constant BW_APP_MESSAGES_R081: natural := no_bits_natural(MAX_CHECK_DEGREE_R081 - 1);

end pkg_param_derived;
