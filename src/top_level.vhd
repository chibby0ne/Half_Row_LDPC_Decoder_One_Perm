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
        input: in std_logic_vector(MAX_CHV - 1 downto 0);

        -- outputs
        valid_output: out std_logic;
        output: out std_logic_vector(MAX_CHV - 1 downto 0));
end entity top_level;
--------------------------------------------------------
architecture circuit of top_level is

    -- signals by every module 
    signal clk: std_logic;


    -- signals used as in/out APP and its muxes
    signal mux_app_input_in_cnb: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_input_in_newcode: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_input_out: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_output_in_app: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_output_in_dummy: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_output_in_newcode: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0) := (others => '0');
    signal mux_app_output_out: t_asdasd; 
    

    
    -- signals used in app
    signal app_in: t_app ;
    signal app_out: t_app ;
    
    -- signals used by permutation networks
    signal perm_input: std_logic;
    signal perm_output: std_logic;
    
    -- signals used by cnbs
    signal sum: std_logic := '0';
    
    
    -- singals used by controller
    signal rst: std_logic;
    signal ena_vc: std_logic;
    signal ena_rp: std_logic;
    signal ena_ct: std_logic;
    signal ena_cf: std_logic;
    signal valid_output: std_logic;
    signal iter: std_logic;
    signal app_rd_addr: std_logic;
    signal app_wr_addr: std_logic;
    signal msg_rd_addr: t_msg_ram_addr;
    signal msg_wr_addr: t_msg_ram_addr;
    signal shift: t_shift_contr;
    signal mux_input_app: std_logic;        
    signal mux_output_app:t_mux_out_app;

   
begin

    
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
    gen_pemutation_network_output_conex: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        cnb_input(i) <= perm_output(i);
    end generate gen_pemutation_network_output_conex;
    

    --------------------------------------------------------------------------------------
    -- cnbs intantiations
    --------------------------------------------------------------------------------------
    gen_cnbs: for i in CFU_PAR_LEVEL - 1 downto 0 generate
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
        app_in => app_in,
        app_out => app_out
        );
    end generate gen_cnbs;

    
    --------------------------------------------------------------------------------------
    -- connections between cnbs and mux at input of apps
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
             mux_input_app => mux_input_app,
             mux_output_app => mux_output_app
    );

    
    
    --------------------------------------------------------------------------------------
    -- connections between controller and all the circuits
    --------------------------------------------------------------------------------------



end architecture circuit;

