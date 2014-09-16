--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: tb_top_level.vhd
--! @brief: testbench for top level
--! @author: Antonio Gutierrez
--! @date: 2014-06-20
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_components.all;
use work.pkg_param.all;
--------------------------------------------------------
entity tb_top_level is
    generic (CLK_PERIOD: time := 40 ns;
            PD: time := 3 ns);
end entity tb_top_level;
--------------------------------------------------------
architecture circuit of tb_top_level is

    
    --------------------------------------------------------------------------------------
    -- component declaration
    --------------------------------------------------------------------------------------
    component top_level is
        port (
        -- inputs
                 clk: in std_logic;
                 rst: in std_logic;
                 code_rate: in t_code_rate;
                 input: in t_app_message_half_codeword;

        -- outputs
                 new_codeword: out std_logic;
                 valid_output: out std_logic;
                 output: out t_hard_decision_full_codeword);
    end component top_level;



    --------------------------------------------------------------------------------------
    -- signal declaration 
    --------------------------------------------------------------------------------------
    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';
    signal code_rate_tb: t_code_rate;
    signal input_tb: t_app_message_half_codeword;
    signal new_codeword_tb: std_logic := '0';
    signal valid_output_tb: std_logic := '0';
    signal output_tb: t_hard_decision_full_codeword;

    -- file fin: text open read_mode is "input_decoder_oneword.txt";
    -- file fout: text open read_mode is "output_decoder_oneword_column.txt";
    -- file fin: text open read_mode is "input_decoder_high_SNR_oneword.txt";
    -- file fout: text open read_mode is "output_decoder_high_SNR_oneword.txt";

    -- R050
    file fin: text open read_mode is "input_files/input_decoder_allsnr_r050_cols.txt";
    file fout: text open read_mode is "output_files/output_decoder_allsnr_r050_cols.txt";

    -- R062
    -- file fin: text open read_mode is "input_files/input_decoder_allsnr_r062_cols.txt";
    -- file fout: text open read_mode is "output_files/output_decoder_allsnr_r062_cols.txt";

    -- R075
    -- file fin: text open read_mode is "input_files/input_decoder_allsnr_r075_cols.txt";
    -- file fout: text open read_mode is "output_files/output_decoder_allsnr_r075_cols.txt";
    
    -- R081
    -- file fin: text open read_mode is "input_files/input_decoder_allsnr_r081_cols.txt";
    -- file fout: text open read_mode is "output_files/output_decoder_allsnr_r081_cols.txt";

begin

    --------------------------------------------------------------------------------------
    -- component instantiation
    --------------------------------------------------------------------------------------
    dut: top_level port map (
                                -- inputs
                                clk => clk_tb,
                                rst => rst_tb,
                                code_rate => code_rate_tb,
                                input => input_tb,  

                                -- output
                                new_codeword => new_codeword_tb,
                                valid_output => valid_output_tb,
                                output => output_tb
                            );


    --------------------------------------------------------------------------------------
    -- stimuli generation
    --------------------------------------------------------------------------------------

    -- clk
    clk_tb <= not clk_tb after CLK_PERIOD / 2;


    -- rst
    rst_tb <= '1', '0' after CLK_PERIOD;


    -- code rate
    code_rate_tb <= R050;           -- R050


    -- used to load the first codeword
    -- init <= '1', '0' after CLK_PERIOD;

    -- input
    -- process
    --     variable l: line;
    --     variable val: integer;
    --     variable val_signed: signed(BW_APP - 1 downto 0);
    --
    -- begin
    --     if (not endfile(fin)) then
    --         for i in 0 to 2 * CFU_PAR_LEVEL - 1 loop
    --             for j in 0 to SUBMAT_SIZE - 1 loop
    --                 readline(fin, l);
    --                 read(l, val);
    --                 val_signed := to_signed(val, BW_APP);
    --                 for k in 0 to BW_APP - 1 loop
    --                     input_tb(i * SUBMAT_SIZE * BW_APP + j * BW_APP + k) <= val_signed(k);
    --                 end loop;
    --             -- input_tb(i)(j) <= to_signed(val, BW_APP);    -- uncomment this and comment loop when testing top_level directly (not top_level_wrapper)
    --             end loop;
    --         end loop;
    --         wait for 360 * CLK_PERIOD;
    --     else
    --         assert false
    --         report "end of inputs"
    --         severity failure;
    --         -- wait;
    --     end if;
    -- end process;
    --
    
    -- input 
    process (new_codeword_tb, clk_tb, rst_tb)
        variable l: line;
        variable val: integer;
    begin
        -- if ((init'event and init = '1') or (new_codeword_tb'event and new_codeword_tb = '1')) then
        if (((new_codeword_tb'event and new_codeword_tb = '1') or (clk_tb'event and clk_tb = '1' and new_codeword_tb = '1')) and (rst_tb = '0')) then
            if (not endfile(fin)) then
                for i in 0 to CFU_PAR_LEVEL - 1 loop
                    for j in 0 to SUBMAT_SIZE - 1 loop
                        readline(fin, l);
                        read(l, val);
                        input_tb(i)(j) <= to_signed(val, BW_APP);    -- uncomment this and comment loop when testing top_level directly (not top_level_wrapper)
                    end loop;
                end loop;
            else
                assert false
                report "end of inputs"
                severity note;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------
    -- output comparison
    --------------------------------------------------------------------------------------

    -- process
    --     variable l: line;
    --     variable val: integer := 0;
    --     variable first: boolean := true;
    --
    -- begin
    --     wait for PD;
    --     if (not endfile(fout)) then
    --             -- if (first = true) then
    --             --     first := false;
    --         wait for CLK_PERIOD * 35;
    --             -- else
    --             --     wait for CLK_PERIOD * 33;
    --             -- end if;
    --         for i in 0 to 2 * CFU_PAR_LEVEL - 1 loop
    --             for j in 0 to SUBMAT_SIZE - 1 loop
    --                 readline(fout, l);
    --                 read(l, val);
    --                     -- assert to_integer(unsigned'("" & output_tb(i)(j))) = val                          -- uncomment this and next line and comment the two lines below when testing top_level directly
    --                     -- report "output(" & integer'image(i) & ")(" & integer'image(j) & ") should be = " & integer'image(val) & " but is = " & integer'image(to_integer(unsigned'("" & output_tb(i)(j))))
    --                 assert to_integer(unsigned'("" & output_tb(i * SUBMAT_SIZE + j))) = val 
    --                 report "output(" & integer'image(i * SUBMAT_SIZE + j) & ") should be = " & integer'image(val) & " but is = " & integer'image(to_integer(unsigned'("" & output_tb(i * SUBMAT_SIZE + j))))
    --                 severity failure;
    --             end loop;
    --         end loop;
    --     else
    --         assert false
    --         report "no errors"
    --         severity failure;
    --         -- wait;
    --     end if;
    -- end process;

    process (monitor_finish_iter)
        variable l: line;
        variable val: integer := 0;
        variable first: boolean := true;
    begin
        if (not endfile(fout)) then
            if (monitor_finish_iter'event and monitor_finish_iter = '0') then

                for i in 0 to 2 * CFU_PAR_LEVEL - 1 loop
                    for j in 0 to SUBMAT_SIZE - 1 loop
                        readline(fout, l);
                        read(l, val);
                        assert to_integer(unsigned'("" & output_tb(i)(j))) = val                          -- uncomment this and next line and comment the two lines below when testing top_level directly
                        report "output(" & integer'image(i) & ")(" & integer'image(j) & ") should be = " & integer'image(val) & " but is = " & integer'image(to_integer(unsigned'("" & output_tb(i)(j))))
                        severity failure;
                    end loop;
                end loop;

            end if;
        else
            assert false
            report "no errors"
            severity failure;
        end if;
    end process;

end architecture circuit;
