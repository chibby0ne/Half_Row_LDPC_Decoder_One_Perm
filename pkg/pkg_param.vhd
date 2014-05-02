--!
--! Copyright (C) 2010 - 2011 Creonic GmbH
--!
--! @file
--! @brief  Parameters for the LDPC decoder core
--! @author Philipp Schläfer
--! @date   2010/10/14
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_param is

	-----------------------------
	-- Code Parameters
	-----------------------------

	--! Bits of a complete codeword as defined by the standard.
	constant MAX_CHV        : natural := 672;

	--! Submatrix size.
	constant SUBMAT_SIZE    : natural := 42;

	--! Number of parallel decoding steps -> gives also the number of vn_groups.
    --! Modified to 8 because of Half row based architecture AJGP
	constant CFU_PAR_LEVEL  : natural := 8;

	--! Number of messages the vn can serve in parallel -> gives also the number of cn_groups.
	constant VFU_PAR_LEVEL  : natural := 4;

    --! Number of APP instantiations
    constant APP_INS: natural := 8;

	--! Number of parallel instantiated check nodes
	constant NUM_CFU        :natural := 168;

	--! Maximal number of iterations the decoder can do.
	constant MAX_ITER       : natural := 10;

    --! Maximum number of layer in Parity matrix (for Code rate R050)
    constant MAX_LAYERS: natural := 8;

    --! Depth of msg ram = max layers of parity matrix * 2 (because each subiteration is half layer)
    constant MSG_RAM_DEPTH: natural := MAX_LAYERS * 2;

    --! Depth of app ram = subiterations per layer
    constant APP_RAM_DEPTH: natural := 2;
   


	--!
	--! Define the extrinsic scaling factor to use within the check node.
	--!  - 0 : 0.75
	--!  - 1 : 0.875
	--!
	constant ESF_0_875      : natural := 1;

	--! Multiple code rates are supported if set
--	constant MULTIPLE_CR    : boolean := false;
 	constant MULTIPLE_CR    : boolean := true;

	--! Set the supported code rate for MULTIPLE_CR = 0
	--! 0: R081
	--! 1: R075
	--! 2: R062
	--! 3: R050
	constant SUPPORTED_CR   : natural := 3;


	-----------------------------
	-- Architecture Parameters
	-----------------------------

	-- Pipeline register switches
	-- IN CFU
	constant REG_CFU_IN    : boolean := false;  -- cfu input register
	constant REG_CFU_MID   : boolean := false;  -- cfu internal register after second comp. stage
	constant REG_CFU_OUT   : boolean := false;  -- cfu output register

	-- IN VFU
	constant REG_VFU_IN    : boolean := false;
	constant REG_VFU_MID   : boolean := false;
	constant REG_VFU_OUT   : boolean := false; -- not implemented

	-- Between CFU and VFU
	constant REG_CFU_TO_VFU : boolean := true;
	constant REG_VFU_TO_CFU : boolean := true;

	-- Before and after the pipeline
	constant REG_PIPE_IN    : boolean := true;
	constant REG_PIPE_OUT   : boolean := true;

	-----------------------------
	-- Quantization Parameters
	-----------------------------

	--! Number of bits a channel value is quantized with.
	constant BW_CHV         : natural := 6;
    -- constant BW_CHV         : natural := 5;
--	constant BW_CHV         : natural := 4;

	--! Number of bits the extrinsic values are quantized with.
-- 	constant BW_EXTR        : natural := BW_CHV + 1;
    constant BW_EXTR        : natural := BW_CHV;

	--! Number of bits used for the APP represantation within the variable node.
   	constant BW_APP         : natural := BW_CHV + 3;
-- 	constant BW_APP         : natural := BW_CHV + 2;

    constant MAX_CHECK_DEGREE_R050: natural := 8;
    constant MAX_CHECK_DEGREE_R062: natural := 10;
    constant MAX_CHECK_DEGREE_R075: natural := 15;
    constant MAX_CHECK_DEGREE_R081: natural := 16;

end pkg_param;
