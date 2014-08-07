--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: top_level.vhd
--! @brief: Top level module of decoder
--! @author: Antonio Gutierrez
--! @date: 2014-05-30
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_components.all;
use work.pkg_param.all;
use work.pkg_support.all;
use work.pkg_types.all;
--------------------------------------------------------
entity top_level is
    port (
        clk: in std_logic;
        rst: in std_logic;
        code_rate: in t_code_rate;
        input: in t_app_message_full_codeword; 

        -- outputs
        new_codeword: out std_logic;
        valid_output: out std_logic;
        output: out t_hard_decision_full_codeword);
end entity top_level;
--------------------------------------------------------
architecture circuit of top_level is

    -- signal used in mux selecting input half
    signal input_newcode: t_app_message_half_codeword;

    --signals used in mux selecting input of app from inputs or from CNBs
    signal cnb_output_in_app: t_app_message_half_codeword;

    -- signals used in mux at output of app, used for selecting where does CNBs input come from: dummy, inputs or apps
    signal dummy_values: t_app_messages := (others => to_signed(31, BW_APP));        -- 31 is msg extr msg
    signal mux_output_app_out: t_app_message_half_codeword; 
    
    
    signal app_in: t_app_message_half_codeword ;
    signal app_out: t_app_message_half_codeword ;
    
    -- signals used by permutation networks
    signal perm_input: t_app_message_half_codeword;
    signal perm_output: t_app_message_half_codeword;
    





    -- signals used by cnbs
    signal cnb_input: t_cnb_message_tc_top_level;
    signal cnb_output: t_cnb_message_tc_top_level;

    -- signal used for hard bits
    signal hard_bits_cnb: t_hard_decision_half_codeword;

    
    -- signal for input of output module
    signal output_in: t_hard_decision_half_codeword;
    
    
    
    -- singals used by controller
    signal parity_out: t_parity_out_contr;
    signal parity_out_reg: t_parity_out_contr;
    signal ena_msg_ram: std_logic; 
    signal ena_vc: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);               
    signal ena_rp: std_logic;
    signal ena_ct: std_logic;
    signal ena_cf: std_logic;
    signal finish_iter: std_logic := '0';
    signal iter: t_iter;
    signal app_rd_addr: std_logic;
    signal app_wr_addr: std_logic;
    signal msg_rd_addr: t_msg_ram_addr;    
    signal msg_wr_addr: t_msg_ram_addr;
    signal shift: t_shift_contr;

    signal sel_mux_input_halves: std_logic;     -- selects which half is being stored 
    signal sel_mux_input_app: std_logic;        
    signal sel_mux_output_app: t_mux_out_app;   -- selects which value to use as CNB input: dummy, from inputs, or from app

    signal split: std_logic := '0';

   

begin

    
    --------------------------------------------------------------------------------------
    -- muxes to select halves of codeword
    --------------------------------------------------------------------------------------
    gen_mux_input_halves: for i in 0 to CFU_PAR_LEVEL - 1 generate
        mux_input_halves_ins: mux2_1 port map (
            input0 => input(i),            
            input1 => input(CFU_PAR_LEVEL + i),         
            sel => sel_mux_input_halves,
            output => input_newcode(i)
        );
    end generate gen_mux_input_halves;
    

    --------------------------------------------------------------------------------------
    -- mux to select input of app
    --------------------------------------------------------------------------------------
    gen_mux_input_app: for i in 0 to CFU_PAR_LEVEL - 1 generate
        mux_input_app_ins: mux2_1 port map (
            input0 => cnb_output_in_app(i),
            input1 => input_newcode(i),
            sel => sel_mux_input_app,
            output => app_in(i)
        );
    end generate gen_mux_input_app;
    
    
    --------------------------------------------------------------------------------------
    -- apps instantiation
    --------------------------------------------------------------------------------------
    gen_app_ram: for i in 0 to CFU_PAR_LEVEL - 1 generate
        app_ram_ins: app_ram port map (
            clk => clk,
            we => ena_vc(i),
            wr_address => app_wr_addr,
            rd_address => app_rd_addr,
            data_in => app_in(i),
            data_out => app_out(i)
        );
    end generate gen_app_ram;


    --------------------------------------------------------------------------------------
    -- input to output module
    --------------------------------------------------------------------------------------
    gen_input_output_module: for i in 0 to CFU_PAR_LEVEL - 1 generate
        gen_input_output_module_detail: for j in 0 to SUBMAT_SIZE - 1 generate
            output_in(i)(j) <= app_out(i)(j)(BW_APP - 1);
        end generate gen_input_output_module_detail;
    end generate gen_input_output_module;


    --------------------------------------------------------------------------------------
    -- muxes at output of apps instantiations
    --------------------------------------------------------------------------------------
    gen_mux_output_app_ins: for i in 0 to CFU_PAR_LEVEL - 1 generate
        mux3_1ins: mux3_1 port map (
            input0 => app_out(i),
            input1 => dummy_values,
            input2 => input_newcode(i),
            sel => sel_mux_output_app(i),                     -- because 0th is MS and matrix_addr starts from 0 onward
            output => mux_output_app_out(i)
        );
    end generate gen_mux_output_app_ins;

    
    --------------------------------------------------------------------------------------
    -- connection between muxes at output of apps and permutation networks
    --------------------------------------------------------------------------------------
    gen_permutation_network_input_conex: for i in 0 to CFU_PAR_LEVEL - 1 generate
        perm_input(i) <= mux_output_app_out(i);
    end generate gen_permutation_network_input_conex;
    

    --------------------------------------------------------------------------------------
    -- permutation network instantiation
    --------------------------------------------------------------------------------------
    gen_permutation_network: for i in 0 to CFU_PAR_LEVEL - 1 generate
        perm_net_ins: permutation_network port map (
            input => perm_input(i),
            shift => shift(i),                            -- because 0th is MS and matrix_offset starts from 0 onward
            output => perm_output(i)
        );
    end generate gen_permutation_network;
    

    --------------------------------------------------------------------------------------
    -- connection between permutation networks and cnbs
    --------------------------------------------------------------------------------------
    gen_permutation_network_output_conex_detail: for j in 0 to SUBMAT_SIZE - 1 generate
        gen_permutation_network_output_conex: for i in 0 to CFU_PAR_LEVEL - 1 generate
            cnb_input(j)(i) <= perm_output(i)(j);
        end generate gen_permutation_network_output_conex;
    end generate gen_permutation_network_output_conex_detail;


    --------------------------------------------------------------------------------------
    -- parity out input from app
    --------------------------------------------------------------------------------------
    gen_parity_out: for i in 0 to SUBMAT_SIZE - 1 generate
        gen_parity_out_detail: for j in 0 to CFU_PAR_LEVEL - 1 generate
            parity_out(i)(j) <= cnb_input(i)(j)(BW_APP - 1);
        end generate gen_parity_out_detail;
    end generate gen_parity_out;

    -- register parity_out to avoid glitches, and input that to the controller
    process (rst, clk)
    begin
        if (rst = '1') then
            parity_out_reg <= (others => (others => '0'));
        elsif (clk'event and clk = '1') then
            parity_out_reg <= parity_out;
        end if;
    end process;


    --------------------------------------------------------------------------------------
    -- cnbs intantiations
    --------------------------------------------------------------------------------------
    gen_cnbs: for j in 0 to SUBMAT_SIZE - 1 generate
        cnbs_ins: check_node_block port map (
        rst => rst,
        clk => clk,
        split => split,
        ena_msg_ram => ena_msg_ram,
        ena_vc => ena_vc,
        ena_rp => ena_rp,
        ena_ct => ena_ct,
        ena_cf => ena_cf,
        iter => iter,
        addr_msg_ram_read => msg_rd_addr,
        addr_msg_ram_write => msg_wr_addr,
        app_in => cnb_input(j),
        app_out => cnb_output(j)
    );
    end generate gen_cnbs;

    
    --------------------------------------------------------------------------------------
    -- gather signals from all the CNBs to inputs to respectives APPs
    --------------------------------------------------------------------------------------
    gen_input_app_from_cnbs_detail: for j in 0 to SUBMAT_SIZE - 1 generate
        gen_input_apps_from_cnbs: for i in 0 to CFU_PAR_LEVEL - 1 generate
            cnb_output_in_app(i)(j) <= cnb_output(j)(i);
        end generate gen_input_apps_from_cnbs;
    end generate gen_input_app_from_cnbs_detail;
        

    --------------------------------------------------------------------------------------
    -- output ordering
    --------------------------------------------------------------------------------------
    output_module_ins: output_module_inver port map (
            rst => rst,
            clk => clk,
            finish_iter => finish_iter,
            code_rate => code_rate,
            input => output_in,
            output => output
    );


    --------------------------------------------------------------------------------------
    -- controller instantiation
    --------------------------------------------------------------------------------------
    controller_ins: controller port map (
             -- inputs
             clk => clk,
             rst => rst,
             code_rate => code_rate,
             parity_out => parity_out_reg,

             -- outputs
             ena_msg_ram => ena_msg_ram,
             ena_vc => ena_vc,
             ena_rp => ena_rp,
             ena_ct => ena_ct,
             ena_cf => ena_cf,
             new_codeword => new_codeword,
             valid_output => valid_output,
             finish_iter => finish_iter,
             iter => iter,
             app_rd_addr => app_rd_addr,
             app_wr_addr => app_wr_addr,
             msg_rd_addr => msg_rd_addr,
             msg_wr_addr => msg_wr_addr,
             shift => shift,
             sel_mux_input_halves => sel_mux_input_halves,
             sel_mux_input_app => sel_mux_input_app,
             sel_mux_output_app => sel_mux_output_app
    );

    
end architecture circuit;
