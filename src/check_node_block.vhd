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
use work.pkg_param_derived.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_components.all;
use work.pkg_ieee_802_11ad_param.all;



entity check_node_block is
    port (
        rst: in std_logic;
        clk: in std_logic;
        ena_msg_ram: in std_logic;
        ena_vc: in std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
        ena_rp: in std_logic;
        ena_ct: in std_logic;
        ena_cf: in std_logic;
        iter: in t_iter;
        addr_msg_ram_read: in t_msg_ram_addr;
        addr_msg_ram_write: in t_msg_ram_addr;
        app_in: in t_cnb_message_tc;   -- input type has to be of CFU_PAR_LEVEL because that's the number of edges that CFU handle
        
    -- outputs
        app_out: out t_cnb_message_tc  -- output type should be the same as input
); 
end entity check_node_block;

architecture circuit of check_node_block is

    
    -- signals used by msg ram
    signal extrinsic_info_read: t_cn_message;
    signal extrinsic_info_write: t_cn_message;
    signal zero: signed(BW_EXTR - 1 downto 0) := to_signed(0, BW_EXTR);
    
    

    -- signals used for FIFOs
    signal zetas: t_cnb_message_tc;     -- signed(BW_APP)
    signal zetas_fifo_intermediate: t_cnb_message_tc;   --signed(BW_APP)
    signal zetas_fifo_out: t_cnb_message_tc;        -- signed (BW_APP)

    
    -- check node
    signal zetas_saturated: t_cn_message;   -- signed(BW_EXTR) 2's complement
    signal zetas_saturated_sign_magn: t_cn_message; -- signed(BW_EXTR) sign-mag
    signal check_node_in_reg_in: t_cn_message;     -- signal before register at input of CN
    signal check_node_in_reg_out: t_cn_message;     -- signal after register at input of CN
    signal check_node_out: t_cn_message;            -- signal output of CN


    -- signal used for typecasting iteration count
    signal iter_int: integer range 0 to 2**BW_MAX_ITER - 1;

    
    -- signals used to register input to CNB
    signal app_in_reg: t_cnb_message_tc;
    signal iter_int_reg: integer range 0 to 2**BW_MAX_ITER - 1;
    signal addr_msg_ram_read_reg: std_logic_vector(BW_MSG_RAM - 1 downto 0);
    signal addr_msg_ram_write_reg: std_logic_vector(BW_MSG_RAM - 1 downto 0);
    

begin
    

    --------------------------------------------------------------------------------------
    -- Type casting entity's ports
    --------------------------------------------------------------------------------------
    iter_int <= to_integer(unsigned(iter));


    --------------------------------------------------------------------------------------
    -- VC stage: Read APP to CNB
    --------------------------------------------------------------------------------------
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (ena_rp = '1') then
                app_in_reg <= app_in;
                iter_int_reg <= iter_int;
                addr_msg_ram_read_reg <= addr_msg_ram_read;
                -- addr_msg_ram_write_reg <= addr_msg_ram_write;
            end if;
        end if;
    end process;

    
    --------------------------------------------------------------------------------------
    -- message ram instantiation
    --------------------------------------------------------------------------------------
    msg_ram_ins: msg_ram port map (
        clk => clk,
        we => ena_msg_ram,
        -- wr_address => addr_msg_ram_write_reg,
        wr_address => addr_msg_ram_write,
        rd_address => addr_msg_ram_read_reg,
        data_in => extrinsic_info_write,
        data_out => extrinsic_info_read
    );
    
    
    --------------------------------------------------------------------------------------
    -- substract the APPin with E(i-1) and store that value in a FIFO so that we can
    --------------------------------------------------------------------------------------
    subs: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        zetas(i) <= app_in_reg(i) when iter_int_reg = 0 else                 -- for first iteration we skip substraction
                    app_in_reg(i) - extrinsic_info_read(i);                  -- for the rest
    end generate subs;

    
    --------------------------------------------------------------------------------------
    -- saturate all the zetas
    --------------------------------------------------------------------------------------
    saturates: for i in CFU_PAR_LEVEL - 1 downto 0  generate
        zetas_saturated(i) <= saturate(zetas(i), BW_EXTR);
    end generate saturates;

    
    --------------------------------------------------------------------------------------
    -- 2's complement to sign-magnitude
    --------------------------------------------------------------------------------------
    twos_comp_sign_magn: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        zetas_saturated_sign_magn(i) <= sign_magnitude(zetas_saturated(i));
    end generate twos_comp_sign_magn;

    
    --------------------------------------------------------------------------------------
    -- input for CN is ready, but needs to be registered (pipeline stage RP)
    --------------------------------------------------------------------------------------
    check_node_in_reg_in <= zetas_saturated_sign_magn;


    --------------------------------------------------------------------------------------
    -- pipeline register before the input to CN (Check Node) Pipeline stage RP
    --------------------------------------------------------------------------------------
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (ena_ct = '1') then
                check_node_in_reg_out <= check_node_in_reg_in;
            end if;
        end if;
    end process;


    --------------------------------------------------------------------------------------
    -- instantiate one CFU and connect the inputs to it
    --------------------------------------------------------------------------------------
    check_node_ins: check_node port map (
                                            rst => rst,
                                            clk => clk,
                                            ena_cf => ena_cf,
                                            data_in => check_node_in_reg_out,
                                            data_out => check_node_out
                                        );
    
    
    --------------------------------------------------------------------------------------
    -- write new extrinsic info in message ram
    --------------------------------------------------------------------------------------
    gen_mux_input_msg_ram: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        muxes_input_ram: mux2_1_msg_ram port map (
            input0 => zero,
            input1 => check_node_out(i),
            sel => ena_vc(i),
            output => extrinsic_info_write(i)
        );
    end generate gen_mux_input_msg_ram;


    --------------------------------------------------------------------------------------
    -- FIFOs used to store the A priori info (Zn->m)
    --------------------------------------------------------------------------------------
    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (ena_ct = '1') then
                for i in CFU_PAR_LEVEL-1 downto 0 loop
                    zetas_fifo_intermediate(i) <= zetas(i);
                end loop;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if (clk'event and clk = '1') then
            if (ena_cf = '1') then
                for i in CFU_PAR_LEVEL - 1 downto 0 loop
                    zetas_fifo_out(i) <= zetas_fifo_intermediate(i);
                end loop;
            end if;
        end if;
    end process;
    

    --------------------------------------------------------------------------------------
    -- sum all the zetas with the output of check_node
    --------------------------------------------------------------------------------------
    gen_new_app_sum: for i in CFU_PAR_LEVEL - 1 downto 0 generate
        app_out(i) <= zetas_fifo_out(i) + check_node_out(i);
    end generate gen_new_app_sum;


end architecture circuit;
