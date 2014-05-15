--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: check_node_block_tb.vhd
--! @brief: tb for check node bloc
--! @author: Antonio Gutierrez
--! @date: 2014-04-23
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.pkg_support.all;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_types.all;
--------------------------------------------------------
entity check_node_block_tb is
    generic (PERIOD: time := 40 ns;
            PD: time := 3 ns);
end entity check_node_block_tb;
--------------------------------------------------------
architecture circuit of check_node_block_tb is
    
    
    --------------------------------------------------------------------------------------
    -- dut declaration
    --------------------------------------------------------------------------------------
    component check_node_block is
    port (

    -- inputs
        rst: in std_logic;
        clk: in std_logic;
        split: in std_logic;
        iter: in t_iter;
        addr_msg_ram_read: in t_msg_ram_addr;
        addr_msg_ram_write: in t_msg_ram_addr;
        app_in: in t_cnb_message_tc;   -- input type has to be of CFU_PAR_LEVEL because that's the number of edges that CFU handle
        
    -- outputs
        app_out: out t_cnb_message_tc  -- output type should be the same as input
    );

    end component check_node_block;

    
    --------------------------------------------------------------------------------------
    -- signals declaration
    --------------------------------------------------------------------------------------
    signal rst_tb: std_logic := '0';
    signal clk_tb: std_logic := '0';
    signal split_tb: std_logic := '0';
    signal iter_tb: t_iter := (others => '0');
    signal addr_msg_ram_read_tb: t_msg_ram_addr;
    signal addr_msg_ram_write_tb: t_msg_ram_addr;
    signal app_in_tb: t_cnb_message_tc;
    signal app_out_tb: t_cnb_message_tc;
    
    file fin: text open read_mode is "input_app_whole_iter.txt";       -- used for entering app_in
    file fout: text open read_mode is "output_app_whole_iter.txt";     -- used for comparing app_out
    
    
    


begin
    
    
    --------------------------------------------------------------------------------------
    -- dut instantiation
    --------------------------------------------------------------------------------------
    dut: check_node_block port map (
        rst => rst_tb,
        clk => clk_tb,
        split => split_tb,
        iter => iter_tb,
        addr_msg_ram_read => addr_msg_ram_read_tb,
        addr_msg_ram_write => addr_msg_ram_write_tb,
        app_in => app_in_tb,
        app_out => app_out_tb
    );

    
    --------------------------------------------------------------------------------------
    -- stimuli generation
    --------------------------------------------------------------------------------------
    -- rst
    rst_tb <= '0';

    -- clk
    clk_tb <= not clk_tb after PERIOD / 2;
    
    --split
    split_tb <= '0';

    -- iter
    iter_tb <= std_logic_vector(to_unsigned(1, BW_MAX_ITER)) after PERIOD/2 + PD + PERIOD * 15;  -- see drawing for explanation

    -- addr_msg_ram_read
    process
    begin
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(0, BW_MSG_RAM));
        wait for PD;
        wait for PERIOD / 2; -- 23 
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(1, BW_MSG_RAM));
        wait for PERIOD;    -- 63
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(2, BW_MSG_RAM));
        wait for PERIOD;    -- 103
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(3, BW_MSG_RAM));
        wait for PERIOD;    -- 143
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(4, BW_MSG_RAM));
        wait for PERIOD;    -- 183
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(5, BW_MSG_RAM));
        wait for PERIOD;    -- 223
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(6, BW_MSG_RAM));
        wait for PERIOD;    -- 263
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(7, BW_MSG_RAM));
        wait for PERIOD;    -- 303
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(8, BW_MSG_RAM));
        wait for PERIOD;    -- 343
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(9, BW_MSG_RAM));
        wait for PERIOD;    -- 383
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(10, BW_MSG_RAM));
        wait for PERIOD;    -- 423
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(11, BW_MSG_RAM));
        wait for PERIOD;    -- 463
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(12, BW_MSG_RAM));
        wait for PERIOD;    -- 503
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(13, BW_MSG_RAM));
        wait for PERIOD;    -- 543
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(14, BW_MSG_RAM));
        wait for PERIOD;    -- 583
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(15, BW_MSG_RAM));
        wait for PERIOD;    -- 603
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(0, BW_MSG_RAM));
        wait for PERIOD;    -- 643
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(1, BW_MSG_RAM));
        wait for PERIOD;    -- 683
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(2, BW_MSG_RAM));
        wait for PERIOD;    -- 723
        addr_msg_ram_read_tb <= std_logic_vector(to_unsigned(3, BW_MSG_RAM));
        wait for PERIOD;    -- 763
        wait;
    end process;

    -- addr_msg_ram_write
    process
    begin

        wait for PD;
        wait for PERIOD/ 2;
        wait for 1 * PERIOD;    -- becasue it is registered we need to send it one cycle before 
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(0, BW_MSG_RAM));
        wait for PERIOD;        -- 
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(1, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(2, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(3, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(4, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(5, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(6, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(7, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(8, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(9, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(10, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(11, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(12, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(13, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(14, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(15, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(0, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(1, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(2, BW_MSG_RAM));
        wait for PERIOD;
        addr_msg_ram_write_tb <= std_logic_vector(to_unsigned(3, BW_MSG_RAM));
        wait;
    end process;
    
    -- app_in
    process
        variable l: line;
        variable value: integer range -256 to 255;
        variable first: integer range 0 to 1 := 0;
    begin
        if (not endfile(fin)) then
            for i in 0 to CFU_PAR_LEVEL - 1 loop
                readline(fin, l);
                read(l, value);
                app_in_tb(i) <= to_signed(value, BW_APP);
            end loop;
            if (first = 0) then
                first := 1;
                wait for PD;                -- 3 
                wait for PERIOD / 2;            -- 23
            else
                wait for PERIOD;            -- 63, 103, 143, 143
            end if;
        else
            wait;
        end if;
    end process;


    --------------------------------------------------------------------------------------
    -- output comparison
    --------------------------------------------------------------------------------------
    process
        variable l: line;
        variable value: integer range -256 to 255;
        variable first: integer range 0 to 1 := 0;
    begin
        if (not endfile(fout)) then
            if (first = 0) then
                first := 1;
                wait for PD;                -- 3
                wait for PERIOD / 2;        -- 23
                wait for 2 * PERIOD;        -- 103
            end if;
            for i in 0 to CFU_PAR_LEVEL - 1 loop
                readline(fout, l);
                read(l, value);
                assert (app_out_tb(i) = to_signed(value, BW_APP))
                report "output mismatch at time " & time'image(NOW)
                severity failure;
            end loop;
            wait for PERIOD;            -- 143, 183, 223, 243 
        else
            assert false
            report "no errors!"
            severity failure;
        end if;
    end process;

end architecture circuit;

