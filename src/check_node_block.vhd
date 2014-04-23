--! 
--! @file: check_node_block.vhd
--! @brief: check node block for layered decoding
--! @author: Antonio Gutierrez
--! @date: 2013-11-07
--!
--!

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_param.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_components.all;
use work.pkg_ieee_802_11ad_param.all;



entity check_node_block is
--generic declarations
    port (
        rst: in std_logic;
        clk: in std_logic;
        split: in std_logic;
        iter: in std_logic_vector(BW_MAX_ITER - 1 downto 0);
        addr_msg_ram: in std_logic_vector(log2(MAX_ADDR) - 1 downto 0);
        app_in: in t_cnb_message_tc;   -- input type has to be of CFU_PAR_LEVEL because that's the number of edges that CFU handle
        
    -- outputs
        app_out: out t_cnb_message_tc  -- output type should be the same as input
); 
end entity check_node_block;

architecture circuit of check_node_block is

    
    -- signals used for type casting 
    signal iter_uns: unsigned(MAX_ITER - 1 downto 0);
    signal addr_msg_ram_uns: unsigned(MAX_ADDR - 1 downto 0);
    
    -- signals that may be registered
    signal check_node_in_i: t_cn_message;
    signal check_node_out_i: t_cn_message;
    
    -- message ram 
    signal msg_ram: t_msg_ram;      

    -- signals used for shift_register
    signal temp_app: t_cnb_message_tc;
    signal temp_app_shift_register_out: t_cnb_message_tc;

    
    -- check node
    signal check_node_in: t_cn_message;
    signal check_node_out: t_cn_message;
    signal check_node_parity_out: std_logic_vector(1 downto 0);


begin
    
    -- substract the APPin with E(i-1) and store that value in a FIFO so that we can
    subs: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        temp_app(i) <= app_in(i) when iter = 0 else                 -- for first iteration we skip substraction
                       app_in(i) - t_msg_ram(addr_msg_ram, i);      -- for the rest
    end generate subs;

    
    -- saturate all the temp_app
    saturate: for i in CFU_PAR_LEVEL -1 downto 0  generate
        check_node_in_i(i) <= saturate(temp_app(i), BW_EXTR)
    end generate saturate;


    -- instantiate one CFU and connect the inputs to it
    check_node_ins: check_node port map (
                                            rst => rst,
                                            clk => clk,
                                            data_in => check_node_in,
                                            split => split,

                                            data_out => check_node_out,
                                            parity_out => check_node_parity_out
                                        );

    
    --
    -- Shift register (FIFO in Thesis' figure)
    --
    -- calculation of number of stages of shift register 

    --  IDEA: use same procedure as in check node!!
    stage_0 <= 1 when REG_CFU_IN = true else 0;

    stage_1 <= 1 when REG_CFU_MID = true else 0;

    stage_2 <= 1 when REG_VFU_TO_CFU = true else 0;

    stage_3 <= 1 when REG_CFU_TO_VFU = true else 0;


    -- need to instantiate a FIFO and connect it to temp_app
    shift_registers: for i in VFU_PAR_LEVEL - 1 downto 0 generate
        shift_register_ins: shift_register port map (
                                    rst => rst,
                                    clk => clk,
                                    stages => stage_0 + stage_1 + stage_2 + stage_3,
                                    input => temp_app(i),
                                    output => temp_app_shift_register_out(i)
                                );
    end generate shift_registers;

    
    -- sum all the temp_apps with the output of check_node
    gen_new_app_sum: for i in VFU_PAR_LEVEL - 1 downto 0 generate
        app_out_i(i) <= temp_app_shift_register_out(i) + check_node_out_i(i);
    end generate gen_new_app_sum;


    --
    -- These processes insert registers if requested
    --


    -- Insert no registers between VFU to CFU
    gen_noreg_input_cfu: if REG_VFU_TO_CFU = false generate

        check_node_in <= check_node_in_i;

    end generate gen_noreg_input_cfu;


    -- Insert registers between VFU to CFU
    gen_reg_input_cfu: if REG_VFU_TO_CFU = true generate

        check_node_in <= check_node_in_reg;

        pr_reg_vfu_cfu: process (clk)
        begin
            if (rising_edge(clk)) then
                check_node_in_reg <= check_node_in_i;
            end if;
        end process pr_reg_vfu_cfu;

    end generate gen_reg_input_cfu;


    -- Insert no registers between CFU to VFU
    gen_noreg_output_cfu: if REG_CFU_TO_VFU = false  generate

        check_node_out_i <= check_node_out;

    end generate gen_noreg_output_cfu;


    -- Insert register between CFU to VFU
    gen_reg_output_cfu: for REG_CFU_TO_VFU = true in range generate

        check_node_out_i <= check_node_out_reg;

        pr_reg_cfu_vfu: process (clk)
        begin
            if (rising_edge(clk)) then
                check_node_out_reg <= check_node_out;
            end if;
        end process pr_reg_cfu_vfu;

    end generate gen_reg_output_cfu;

end architecture circuit;
