--!
--! Copyright (C) 2010 - 2011 Creonic GmbH
--!
--! @file   pkg_components.vhd
--! @brief  Package holding all component interface declarations
--! @author Philipp Schläfer
--! @date   2010/10/14
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_support_global.all;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_types.all;
-- use work.pkg_pipe.all;
use work.pkg_check_node.all;


package pkg_components is


	component variable_node is
		port(
			-- INPUTS
			data_in             : in t_vn_message;
			intrinsic_message   : in signed(BW_CHV - 1 downto 0);

			-- OUTPUTS
			data_out            : out t_vn_message;
			hard_decision       : out std_logic
		);
	end component;


	component check_node is
		port(

			-- INPUTS
			rst           : in std_logic;
			clk           : in std_logic;
			data_in       : in t_cn_message;
			split         : in std_logic; -- is the CN working in split mode

			-- OUTPUTS
			data_out      : out t_cn_message;
			-- parity_out    : out std_logic_vector(1 downto 0)
			parity_out    : out std_logic
		);
	end component;


    component app_ram is
        port (
                 clk: in std_logic;
                 wr_address: in std_logic_vector(BW_APP_RAM - 1 downto 0);
                 rd_address: in std_logic_vector(BW_APP_RAM - 1 downto 0);
                 data_in: in t_app_messages;
                 data_out: out t_app_messages);
    end component app_ram;


    component msg_ram is
        port (
                 clk: in std_logic;
                 wr_address: in std_logic_vector(BW_MSG_RAM - 1 downto 0);
                 rd_address: in std_logic_vector(BW_MSG_RAM - 1 downto 0);
                 data_in: in t_cn_message;
                 data_out: out t_cn_message);
    end component msg_ram;


-- component net_chan_to_cfu is
-- 	port(
-- 		-- Config
-- 		code_rate : in t_code_rate;
--
-- 		-- Channel values
-- 		chv_val : in t_chv_array;
--
-- 		-- Check node inputs
-- 		chv_to_cfu : out t_cfu_array
--
-- 	);
-- end component;
--
-- component net_cfu_to_vfu is
-- 	port(
-- 		-- Config
-- 		code_rate : in t_code_rate;
--
-- 		cfu_out   : in t_cfu_array;
--
-- 		vfu_in    : out t_vfu_array
--
-- 	);
-- end component;
--
-- component net_vfu_to_cfu is
-- 	port(
-- 		-- Config
-- 		code_rate : in t_code_rate;
--
-- 		vfu_out   : in t_vfu_array;
--
-- 		cfu_in    : out t_cfu_array
--
-- 	);
	-- end component;
    --
    --
	-- component pipe is
	-- 	port(
	-- 		-- Global I/O
	-- 		clk     : in  std_logic;
	-- 		rst     : in  std_logic;
    --
	-- 		-- Config
	-- 		code_rate : in t_code_rate;
    --
	-- 		-- Channel values
	-- 		chv_val : in t_chv_array;
	-- 		chv_val_valid : in std_logic;
    --
	-- 		-- Decoding results
	-- 		dec_bits         : out std_logic_vector(NUM_VFU - 1 downto 0);
	-- 		dec_bits_valid   : out std_logic -- TODO set
	-- 	);
	-- end component;

end pkg_components;
