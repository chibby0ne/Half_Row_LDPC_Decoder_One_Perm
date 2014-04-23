--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: check_node_tb.vhd
--! @brief: testbench for check node
--! @author: Antonio Gutierrez
--! @date: 2014-04-14
--!
--!
--------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.pkg_types.all;
use work.pkg_param.all;
--------------------------------------
entity check_node_tb is
    generic (PERIOD: time := 40 ns;
             PD: time := 3 ns);
end entity check_node_tb;
--------------------------------------
architecture circuit of check_node_tb is
    
    -- dut declaration
    component check_node is
        -- generic(const_name const_type = const_value)
        port(

    -- INPUTS
                rst           : in std_logic;
                clk           : in std_logic;
                data_in       : in t_cn_message;
                split         : in std_logic; -- is the CN working in split mode

    -- OUTPUTS
                data_out      : out t_cn_message;
                parity_out    : out std_logic_vector(1 downto 0)
            );

    end component check_node;
    
    -- signal declarations
    signal rst_tb: std_logic := '0';
    signal clk_tb: std_logic := '0';
    signal data_in_tb: t_cn_message;
    signal split_tb: std_logic := '0';
    signal data_out_tb: t_cn_message;
    signal parity_out_tb: std_logic_vector(1 downto 0);
    
    file f: text open read_mode is "input_cn.txt";
    file f_comp: text open read_mode is "output_cn.txt";
    signal first: std_logic := '0';
    -- signal half: boolean := false;

begin

    
    -- dut instatiation
    dut: check_node port map (
        rst => rst_tb,
        clk => clk_tb,
        data_in => data_in_tb,
        split => split_tb, 
        data_out => data_out_tb,
        parity_out => parity_out_tb
    );

    
    -- stimuli generation

    -- clk
    clk_tb <= not clk_tb after PERIOD/2;
    
    -- rst
    rst_tb <= '0' after PERIOD;

    
    -- data_in_tb && data_out comparison
    process
        -- for input
        variable l: line;
        variable input_val: integer range -32 to 31;
        variable index_input: natural range 0 to 16;
        variable i: natural := 0;

        -- for output
        variable l_comp: line;
        variable output_val: integer range -32 to 31;
        variable index_output: natural range 0 to 16;
        variable j: natural := 0;

    begin
        if (not endfile(f_comp)) then
            -- report "reading from the input file";

            -- if first time 
            if (first = '0') then

                first <= '1';

                -- read first half of 1st row
                for i in 0 to CFU_PAR_LEVEL-1 loop
                    readline(f, l);  
                    read(l, index_input);
                    read(l, input_val);
                        -- report natural'image(index_input) & ' ' & integer'image(input_val);

                    data_in_tb(i) <= to_signed(input_val, BW_EXTR);

                end loop;

                -- wait for the rising clock edge for the 2nd half of inputs
                wait for PERIOD/2;

                -- read second half of 1st row
                for i in 0 to CFU_PAR_LEVEL-1 loop
                    readline(f, l);  
                    read(l, index_input);
                    read(l, input_val);
                    -- report natural'image(index_input) & ' ' & integer'image(input_val);

                    data_in_tb(i) <= to_signed(input_val, BW_EXTR);

                end loop;

                -- report "reading from the output file";

                -- propagation delay (necessary to read the output)
                    wait for PD;

                -- 1st half of 1st row is now at the output
                -- we can verify the values now
                for j in 0 to CFU_PAR_LEVEL - 1 loop
                    readline(f_comp, l_comp);
                    read(l_comp, index_output);
                    read(l_comp, output_val);
                    -- report natural'image(index_input) & ' ' & integer'image(input_val);


                    assert (data_out_tb(j) = to_signed(output_val, BW_EXTR))
                    report "output mismatch!"
                    severity failure;

                end loop;

                -- wait for the next rising edge
                wait for PERIOD - PD;

            else
                -- from the second rising edge

                if (not endfile(f)) then
                -- read first half of the 2nd row
                    for i in 0 to CFU_PAR_LEVEL-1 loop
                        readline(f, l);  
                        read(l, index_input);
                        read(l, input_val);
                    -- report natural'image(index_input) & ' ' & integer'image(input_val);

                        data_in_tb(i) <= to_signed(input_val, BW_EXTR);

                    end loop;
                end if;

                -- wait for propagation delay (necessary to read outputs)
                wait for PD;

                -- half inputed before the one just inputed is now processed at output 
                for j in 0 to CFU_PAR_LEVEL - 1 loop
                    readline(f_comp, l_comp);
                    read(l_comp, index_output);
                    read(l_comp, output_val);
                    -- report natural'image(index_input) & ' ' & integer'image(input_val);


                    assert (data_out_tb(j) = to_signed(output_val, BW_EXTR))
                    report "output mismatch!"
                    severity failure;

                end loop;

                wait for PERIOD - PD;

            end if;

        else
            assert false
            report "no errors"
            severity failure;
            wait;
        end if;
    end process;

end architecture circuit;
