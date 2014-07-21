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
use work.pkg_check_node.all;


package pkg_components is

    --------------------------------------------------------------------------------------
    -- mux 2 to 1 used in input of app
    --------------------------------------------------------------------------------------
    component mux2_1 is
        port (
                 input0: in t_app_messages;
                 input1: in t_app_messages;
                 sel: in std_logic;
                 output: out t_app_messages
             );
    end component mux2_1;


    --------------------------------------------------------------------------------------
    -- app ram
    --------------------------------------------------------------------------------------
    component app_ram is
        port (
                 clk: in std_logic;
                 we: in std_logic;
                 wr_address: in std_logic;
                 rd_address: in std_logic; 
                 data_in: in t_app_messages;
                 data_out: out t_app_messages
             );
    end component app_ram;


    --------------------------------------------------------------------------------------
    -- mux 3 to 1 used in output of app
    --------------------------------------------------------------------------------------
    component mux3_1 is
        port (
                 input0: in t_app_messages;
                 input1: in t_app_messages;        -- dummy value (max extr msg e.g: 31)
                 input2: in t_app_messages;
                 sel: in std_logic_vector(1 downto 0);
                 output: out t_app_messages);
    end component mux3_1;


    --------------------------------------------------------------------------------------
    -- permutation network
    --------------------------------------------------------------------------------------
    component permutation_network is
        port (
                 input: in t_app_messages;
                 shift: in t_shift_perm_net;
                 output: out t_app_messages
             );
    end component permutation_network;

    --------------------------------------------------------------------------------------
    -- check node block
    --------------------------------------------------------------------------------------
    component check_node_block is
        port (

                 rst: in std_logic;
                 clk: in std_logic;
                 split: in std_logic;
                 ena_rp: in std_logic;
                 ena_ct: in std_logic;
                 ena_cf: in std_logic;
                 iter: in t_iter;
                 addr_msg_ram_read: in t_msg_ram_addr;
                 addr_msg_ram_write: in t_msg_ram_addr;
                 app_in: in t_cnb_message_tc;   -- input type has to be of CFU_PAR_LEVEL because that's the number of edges that CFU handle

        -- outputs
                 app_out: out t_cnb_message_tc;  -- output type should be the same as input
                 check_node_parity_out: out std_logic
             ); 
    end component check_node_block;


    --------------------------------------------------------------------------------------
    -- check node 
    --------------------------------------------------------------------------------------
    component check_node is
        port(
                -- INPUTS
                rst           : in std_logic;
                clk           : in std_logic;
                ena_cf        : in std_logic;
                data_in       : in t_cn_message;
                split         : in std_logic; -- is the CN working in split mode

                -- OUTPUTS
                data_out      : out t_cn_message;
                parity_out    : out std_logic
            );
    end component;


    --------------------------------------------------------------------------------------
    -- msg ram
    --------------------------------------------------------------------------------------
    component msg_ram is
        port (
                 clk: in std_logic;
                 we: in std_logic;
                 wr_address: in t_msg_ram_addr;
                 rd_address: in t_msg_ram_addr;
                 data_in: in t_cn_message;
                 data_out: out t_cn_message
             );
    end component msg_ram;


    --------------------------------------------------------------------------------------
    -- output module
    --------------------------------------------------------------------------------------
    component output_module is
        port (
                 rst: in std_logic;
                 clk: in std_logic;
                 finish_iter: in std_logic;
                 code_rate: in t_code_rate;
                 input: in t_hard_decision_half_codeword;
                 output: out t_hard_decision_full_codeword
             );
    end component output_module;


    --------------------------------------------------------------------------------------
    -- controller
    --------------------------------------------------------------------------------------
    component controller is
        port (
             -- inputs
                 clk: in std_logic;
                 rst: in std_logic;
                 code_rate: in t_code_rate;
                 parity_out: in t_parity_out_contr;

             -- outputs
                 ena_vc: out std_logic;
                 ena_rp: out std_logic;
                 ena_ct: out std_logic;
                 ena_cf: out std_logic;
                 valid_output: out std_logic;
                 finish_iter: out std_logic;
                 iter: out t_iter;
                 app_rd_addr: out std_logic;
                 app_wr_addr: out std_logic;
                 msg_rd_addr: out t_msg_ram_addr;
                 msg_wr_addr: out t_msg_ram_addr;
                 shift: out t_shift_contr;
                 mux_input_halves: out std_logic;
                 mux_input_app: out std_logic;                        -- mux at input of app rams used for storing (0 = CNB, 1 = new code)
                 mux_output_app: out t_mux_out_app                    -- mux output of appram used for selecting input of CNB (0 = app, 1 = dummy, 2 = new_code)
             );
    end component controller;

end pkg_components;
