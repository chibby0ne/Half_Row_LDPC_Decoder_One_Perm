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
        input: in t_message_app_full_codeword; 

        -- outputs
        valid_output: out std_logic;
        output: out t_hard_decision_full_codeword);
end entity top_level;
--------------------------------------------------------
architecture circuit of top_level is



    -- signals used as in/out APP and its muxes
    signal mux_app_input_in_cnb: t_message_app_half_codeword;
    signal mux_app_input_in_newcode: t_message_app_half_codeword;
    signal mux_app_input_out: t_message_app_half_codeword;
    signal mux_app_output_in_app: t_message_app_half_codeword; 
    signal mux_app_output_in_dummy: t_message_app_half_codeword;
    signal mux_app_output_in_newcode: t_message_app_half_codeword;
    signal mux_app_output_out: t_message_app_half_codeword; 
    
    
    
    -- signals used in app
    signal app_in: t_message_app_half_codeword ;
    signal app_out: t_message_app_half_codeword ;
    
    -- signals used by permutation networks
    signal perm_input: t_message_app_half_codeword;
    signal perm_output: t_message_app_half_codeword;
    
    -- signals used by cnbs
    signal cnb_input: t_cnb_message_tc_top_level;
    signal cnb_output: t_cnb_message_tc_top_level;
    signal hard_bits_cnb: t_hard_decision_bits_half_codeword;
    
    
    
    -- singals used by controller
    signal rst: std_logic;
    signal parity_out: t_parity_out_contr;
    signal ena_vc: std_logic;
    signal ena_rp: std_logic;
    signal ena_ct: std_logic;
    signal ena_cf: std_logic;
    signal valid_output: std_logic;
    signal iter: t_iter;
    signal app_rd_addr: std_logic;
    signal app_wr_addr: std_logic;
    signal msg_rd_addr: t_msg_ram_addr;
    signal msg_wr_addr: t_msg_ram_addr;
    signal shift: t_shift_contr;
    signal mux_input_halves: std_logic;
    signal mux_input_app: std_logic;        
    signal mux_output_app: t_mux_out_app;

   
begin

    
    --------------------------------------------------------------------------------------
    -- muxes to select halves of codeword
    --------------------------------------------------------------------------------------
    gen_mux_input_halves: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        mux_input_halves_ins: mux2_1 port map (
            -- change this according to type 0 to 16)
            input0 => input(CFU_PAR_LEVEL - 1 downto 0),
            input1 => input(2 * CFU_PAR_LEVEL - 1 downto CFU_PAR_LEVEL),
            -- input0 => input( ( (MAX_CHV / 2 - 1) - (SUBMAT_SIZE * (CFU_PAR_LEVEL - (i + 1) ) ) ) downto ( MAX_CHV / 2 - (SUBMAT_SIZE * (CFU_PAR_LEVEL - i) ) ) ),      --- calc
            -- input1 => input( ( (MAX_CHV - 1) - (SUBMAT_SIZE * (CFU_PAR_LEVEL - (i + 1) ) ) ) downto ( MAX_CHV - (SUBMAT_SIZE * (CFU_PAR_LEVEL - i) ) ) ),
            sel => mux_input_halves,
            output => mux_app_input_in_newcode(i)
        );
    end generate gen_mux_input_halves;
    

    --------------------------------------------------------------------------------------
    -- muxes at input of apps instantiations
    --------------------------------------------------------------------------------------
    gen_mux_input_app: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        mux_input_app_ins: mux2_1 port map (
            input0 => mux_app_input_in_cnb(i),
            input1 => mux_app_input_in_newcode(i),
            sel => mux_input_app,
            output => mux_app_output_in_app(i)
        );
    end generate gen_mux_input_app;


    --------------------------------------------------------------------------------------
    -- connection between muxes at input of app and apps
    --------------------------------------------------------------------------------------
    gen_mux_input_app_conex: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        app_in(i)  <= mux_app_input_out(i);
    end generate gen_mux_input_app_conex;


    --------------------------------------------------------------------------------------
    -- apps instantiation
    --------------------------------------------------------------------------------------
    gen_app_ram: for i in 0 to CFU_PAR_LEVEL - 1  generate
        app_ram_ins: app_ram port map (
            clk => clk,
            we => enable_vc,
            wr_address => app_wr_addr,
            rd_address => app_rd_addr,
            data_in => mux_app_input_out(i),
            data_out => mux_app_output_in(i)
        );
    end generate gen_app_ram;


    --------------------------------------------------------------------------------------
    -- connection between apps and muxes at output of apps 
    --------------------------------------------------------------------------------------
    gen_app_out_conex: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        mux_app_output_in_app(i) <= app_out(i);
    end generate gen_app_out_conex;


    --------------------------------------------------------------------------------------
    -- muxes at output of apps instantiations
    --------------------------------------------------------------------------------------
    gen_mux_output_app_ins: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        mux3_1ins: mux3_1 port map (
            input0 => mux_app_output_in_app(i),
            input1 => mux_app_output_in_dummy(i),
            input2 => mux_app_output_in_newcode(i),
            sel => mux_output_app(i),
            output => mux_output_out(i)
        );
    end generate gen_mux_output_app_ins;
    

    --------------------------------------------------------------------------------------
    -- connection between muxes at output of apps and permutation networks
    --------------------------------------------------------------------------------------
    gen_permutation_network_input_conex: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        perm_input(i) <= mux_app_output_out(i);
    end generate gen_permutation_network_input_conex;
    

    --------------------------------------------------------------------------------------
    -- permutation network instantiation
    --------------------------------------------------------------------------------------
    gen_permutation_network: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        perm_net_ins: permutation_network port map (
            input => perm_input(i),
            shift => shift(i),
            output => perm_output(i)
        );
    end generate gen_permutation_network;
    

    --------------------------------------------------------------------------------------
    -- connection between permutation networks and cnbs
    --------------------------------------------------------------------------------------
    gen_permutation_network_output_conex_detail: for j in SUBMAT_SIZE - 1 downto 0 generate
        gen_pemutation_network_output_conex: for i in CFU_PAR_LEVEL - 1 downto 0 generate
            cnb_input(j)(i) <= perm_output(i)(j);
        end generate gen_pemutation_network_output_conex;
    end generate gen_permutation_network_output_conex_detail;
    

    --------------------------------------------------------------------------------------
    -- cnbs intantiations
    --------------------------------------------------------------------------------------
    gen_cnbs: for j in SUBMAT_SIZE - 1 downto 0 generate
        cnbs_ins: check_node_block port map (
        rst => rst,
        clk => clk,
        split => split,
        ena_vc => ena_vc,
        ena_rp => ena_rp,
        ena_ct => ena_ct,
        ena_cf => ena_cf,
        iter => iter,
        addr_msg_ram_read => addr_msg_ram_read,
        addr_msg_ram_write => addr_msg_ram_write,
        app_in => cnb_input(j),
        app_out => cnb_output(j),
        hard_bits_cnb => hard_bits_cnb(i)
        );
    end generate gen_cnbs;

    

    --------------------------------------------------------------------------------------
    -- connections between inverse permutation networks and mux at input of apps
    --------------------------------------------------------------------------------------
    gen_cnb_output_app: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        app_out(i) <= mux_input_app(i);
    end generate gen_cnb_output_app;

    
    --------------------------------------------------------------------------------------
    -- controller instantiation
    --------------------------------------------------------------------------------------
    controller_ins: controller port map (
             -- inputs
             clk => clk,
             rst => rst,
             code_rate => code_rate,
             parity_out => parity_out,

             -- outputs
             ena_vc => ena_vc,
             ena_rp => ena_rp,
             ena_ct => ena_ct,
             ena_cf => ena_cf,
             valid_output => valid_output,
             iter => iter,
             app_rd_addr => addr_rd_addr,
             app_wr_addr => addr_wr_addr,
             msg_rd_addr => msg_rd_addr,
             msg_wr_addr => msg_wr_addr,
             shift => shift,
             mux_input_halves => mux_input_halves,
             mux_input_app => mux_input_app,
             mux_output_app => mux_output_app
    );

    
    
    --------------------------------------------------------------------------------------
    -- output ordering
    --------------------------------------------------------------------------------------
    output_module_ins: output_module port map (
        rst => rst,
        clk => clk,
        code_rate => code_rate,
        valid => valid_output,
        input => hard_bits_cnb,
        output => output
    );



end architecture circuit;

