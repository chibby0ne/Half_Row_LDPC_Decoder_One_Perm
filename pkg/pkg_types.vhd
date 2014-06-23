--!
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file   pkg_types.vhd
--! @brief  Package holding global types
--! @author Philipp Schläfer
--! @date   2013/02/02
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_support_global.all;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_ieee_802_11ad_param.all;



package pkg_types is

	-- The available code rates.
	type t_code_rate is (R050, R062, R075, R081);

	type trec_code_param is record
		iterations      : unsigned(BW_MAX_ITER - 1 downto 0);
		code_rate       : t_code_rate;
	end record;

	type t_chv_array is array(NUM_VFU - 1 downto 0) of signed(BW_CHV - 1 downto 0);

    
    type t_out_hard is array (NUM_VFU - 1 downto 0) of std_logic;

    -- Permutation network in/out
    ------------------------------
    -- messages in/out 
    type t_app_messages is array (SUBMAT_SIZE - 1 downto 0) of signed(BW_APP - 1 downto 0);
    
    -- shift value
    subtype t_shift_perm_net is std_logic_vector(BW_SHIFT_VEC - 1 downto 0);
    
    

	-- Variable node types
	------------------------

	-- Array of in/outputs of a variable node
	type t_vn_message is array (VFU_PAR_LEVEL - 1 downto 0) of signed(BW_EXTR - 1 downto 0);

	-- Array of twos complement signals handled by a vn internally
	type t_vn_message_tc is array (VFU_PAR_LEVEL - 1 downto 0) of signed(BW_APP - 1 downto 0);

	type t_vn_addr is array (2 downto 0) of integer;

	-- Check node types
	---------------------

	-- Array of data in/outputs of a check node
    -- type t_cn_message is array (CFU_PAR_LEVEL - 1 downto 0) of std_logic_vector(BW_EXTR - 1 downto 0);
	type t_cn_message is array (CFU_PAR_LEVEL - 1 downto 0) of signed(BW_EXTR - 1 downto 0);
	
	-- Array of magnitude data of a check node
	type t_cn_mag is array (CFU_PAR_LEVEL - 1 downto 0) of unsigned(BW_EXTR - 2 downto 0);



-- Check Node Block 
    ---------------
 -- Added by AJGP
    -- Array of data in/out of a check node block CNB
	type t_cnb_message_tc is array (CFU_PAR_LEVEL - 1 downto 0) of signed(BW_APP - 1 downto 0);

    -- msg ram addr type
    subtype t_msg_ram_addr is std_logic_vector(BW_MSG_RAM - 1 downto 0);

     -- iteration type
    subtype t_iter is std_logic_vector(BW_MAX_ITER - 1 downto 0);

   
    -- APP ram
    -------------
    -- app ram addr
    subtype t_app_ram_addr is std_logic_vector(BW_APP_RAM - 1 downto 0);


    -- MUX at output of APP 
    -----------------------
    type t_mux_out_app is array (CFU_PAR_LEVEL - 1 downto 0) of std_logic_vector(1 downto 0);

    -- Controller types
    ----------------------
    -- 8 APP rams
    type t_app_addr_contr is array (CFU_PAR_LEVEL - 1 downto 0) of t_app_ram_addr;

    -- 42 msg rams (1 per CNB)
    type t_msg_addr_contr is array (SUBMAT_SIZE - 1 downto 0) of t_msg_ram_addr;

    -- 42 CNBs
    type t_parity_out_contr is array (SUBMAT_SIZE - 1 downto 0) of std_logic;

    --- 8 permutations networks
    type t_shift_contr is array (CFU_PAR_LEVEL - 1 downto 0) of t_shift_perm_net;

    -- Top Level
    --------------

    -- 8 of each app message
    type t_message_app_full_codeword is array (2 * CFU_PAR_LEVEL - 1 downto 0) of t_app_messages;
    type t_message_app_half_codeword is array (CFU_PAR_LEVEL - 1 downto 0) of t_app_messages;

    -- 42 of each cnb message
    type t_cnb_message_tc_top_level is array (SUBMAT_SIZE - 1 downto 0) of t_cnb_message_tc;




	-- Pipe types
	--------------
	type t_cfu_array_i is array (SUBMAT_SIZE - 1 downto 0) of t_cn_message;
	type t_cfu_array is array (NUM_SUBMAT_CFU - 1 downto 0) of t_cfu_array_i;
	type t_cfu_array_pipe is array (MAX_ITER downto 0) of t_cfu_array; -- MAX_ITER - 1 downto 0 is sufficient but simulation fails

	type t_vfu_array_i is array (SUBMAT_SIZE - 1 downto 0) of t_vn_message;
	type t_vfu_array is array (NUM_SUBMAT_VFU - 1 downto 0) of t_vfu_array_i;
	type t_vfu_array_pipe is array (MAX_ITER - 1 downto 0) of t_vfu_array;

	type t_vfu_array_tc_i is array (SUBMAT_SIZE - 1 downto 0) of t_vn_message_tc;
	type t_vfu_array_tc is array (NUM_SUBMAT_VFU - 1 downto 0) of t_vfu_array_tc_i;
	type t_vfu_array_pipe_tc is array (MAX_ITER - 1 downto 0) of t_vfu_array_tc;

	type t_split_pipe is array (2*MAX_ITER downto 0) of std_logic_vector(NUM_SUBMAT_CFU-1 downto 0);

	type t_code_rate_pipe is array (2*MAX_ITER downto 0) of t_code_rate;

	type t_chv_array_pipe is array (2*MAX_ITER - 1 downto 0) of t_chv_array;

	type t_dec_bits_pipe is array (MAX_ITER - 1 downto 0) of std_logic_vector(NUM_VFU - 1 downto 0);
	
	type t_dec_bits_valid_pipe is array (MAX_ITER downto 0) of std_logic;

end pkg_types;
