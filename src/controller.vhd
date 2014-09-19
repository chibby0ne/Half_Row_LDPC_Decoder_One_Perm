--! 
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file: controller.vhd
--! @brief: controller for LDPC decoder
--! @author: Antonio Gutierrez
--! @date: 2014-05-02
--!
--!
--------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pkg_support.all;
use work.pkg_types.all;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_ieee_802_11ad_matrix.all;
use work.pkg_ieee_802_11ad_param.all;
--------------------------------------------------------
entity controller is
    port (
        -- inputs
             clk: in std_logic;
             rst: in std_logic;
             code_rate: in t_code_rate;
             parity_out: in t_parity_out_contr;

        -- outputs
             ena_msg_ram: out std_logic;                                -- used for enabling msg ram
             ena_vc: out std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
             ena_rp: out std_logic;
             ena_ct: out std_logic;
             ena_cf: out std_logic;
             new_codeword: out std_logic;
             valid_output: out std_logic;
             finish_iter: out std_logic;
             iter: out t_iter;
             app_rd_addr: out std_logic;
             app_wr_addr: out std_logic;
             msg_rd_addr: out t_msg_ram_addr;
             msg_wr_addr: out t_msg_ram_addr;
             shift: out t_shift_contr;
             shifting_info: out t_shift_contr;
             -- sel_mux_input_halves: out std_logic;     -- mux choosing input codeword halves
             sel_mux_input_app: out std_logic;
             sel_mux_output_app: out t_mux_out_app    -- mux output of appram used for selecting input of CNB (0 = app, 1 = dummy, 2 = new_code)
         );
end entity controller;
--------------------------------------------------------
architecture circuit of controller is

    -- signals used in FSM
    type state is (START_RESET, MATRIX_CALC, FIRST, SECOND, THIRD, FOURTH, FINISH);
    signal pr_state: state;
    signal nx_state: state;
    -- attribute enum_encoding: string;
    -- attribute enum_encoding of state: type is "sequential";


    -- signals used for handling parity check matrix 
    signal addr_length: std_logic;


    -- signals used for paritiy check matrix
    -- I'm choosing the biggest size of them and to address them I'm using the max check degree
    signal matrix_addr: t_array64;      
    signal matrix_shift: t_array64;
    signal matrix_length: natural range 0 to 64;
    signal matrix_rows: natural range 0 to 8;
    signal matrix_max_check_degree: natural range 0 to 16;

    signal matrix_shifting_info: t_array16;
    
    signal matrix_last_row: t_array16;
    
    signal parity_out_reg: t_parity_out_contr;
    
begin


    --------------------------------------------------------------------------------------
    -- Lower section of FSM: sequential part
    -- Here the state transitions is done
    --------------------------------------------------------------------------------------

    process (clk, rst)
    begin
        if (rst = '1') then
            pr_state <= START_RESET;
        elsif (clk'event and clk = '1') then
            pr_state <= nx_state;
        end if;
    end process;
    --------------------------------------------------------


    --------------------------------------------------------------------------------------
    -- Upper section of FSM: combinational part
    -- Here outputs of the FSM are handled, using the inputs as conditions 
    --------------------------------------------------------------------------------------

    process (pr_state)

        -- base address of matrix (cng_counter * matrix_max_check_degree)
        variable vector_addr: integer range 0 to 56;

        -- row number in reduced matrix
        variable cng_counter: integer range 0 to 8;

        -- iteratons
        variable iter_int: integer range 0 to MAX_ITER;

        -- msg rams
        variable msg_row_rd: integer range 0 to 16;
        variable msg_row_wr: integer range 0 to 16;

        -- parity checks
        variable ok_checks: integer range 0 to MAX_CHV / 2;
        variable pchecks: std_logic_vector(SUBMAT_SIZE - 1 downto 0);

        -- start pos
        variable start_pos_next_half: integer range 0 to 64;
        variable index_row: integer range 0 to 64;

        -- finish iterating
        variable next_iter_last_iter: boolean;
        variable complete: boolean;

        -- start iterating
        variable first_time: boolean;
        
        -- aux variables
        variable val: integer range 0 to 1;
        
        variable ena_vc_first: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
        variable ena_vc_second: std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
        
        variable current_row: natural range 0 to 8;
        
    begin
        case pr_state is


            --------------------------------------------------------------------------------------
            -- first state 
            --------------------------------------------------------------------------------------

            when START_RESET =>

                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '0';
                ena_ct <= '0';
                ena_cf <= '0';
                ena_msg_ram <= '0';
                ena_vc <= (others => '0');


                -- first time
                first_time := true;
                current_row := 0;
                iter_int := 0;



                -- variables
                vector_addr := 0;
                cng_counter := 0;

                msg_row_rd := 0;
                msg_row_wr := 0;

                ok_checks := 0;
                pchecks := (others => '0');

                start_pos_next_half := 0;
                index_row := 0;

                next_iter_last_iter := false;
                complete := false;

                first_time := true;

                val := 0;
                ena_vc_first := (others => '0');
                ena_vc_second := (others => '0');

                current_row := 0;



                --
                -- App ram (NOT ENABLED)
                --
                app_rd_addr <= '0';
                app_wr_addr <= '0';
                sel_mux_input_app <= '0';

                parity_out_reg <= (others => (others => '0'));

                --
                -- max_app_val or real app val + real shift 
                --
                cng_counter := 0;
                sel_mux_output_app <= (others => (others => '0'));
                shift <= (others => (others => '0'));



                --
                -- inside CNB                 
                --

                msg_row_rd := 0;
                msg_row_wr := 0;
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));

                iter_int := 0;
                iter <= std_logic_vector(to_unsigned(0, BW_MAX_ITER));
                next_iter_last_iter := false;
                finish_iter <= '0';
                monitor_finish_iter <= '0';

                -- getting new codeword?
                new_codeword <= '0';

                --
                -- resetting valid output
                -- 
                ok_checks := 0;
                valid_output <= '0';


                
                --
                -- next state
                --
                nx_state <= MATRIX_CALC;


                
            --------------------------------------------------------------------------------------
            -- second state (calculate matrix)
            --------------------------------------------------------------------------------------
            when MATRIX_CALC =>

                --
                -- calculate matrix values
                --
                for i in 0 to 63 loop
                    if (code_rate = R050) then
                        matrix_addr(i) <= IEEE_802_11AD_P42_N672_R050_ADDR(i);
                        matrix_shift(i) <= IEEE_802_11AD_P42_N672_R050_OFFSET(i);
                    elsif (code_rate = R062) then
                        if (i < 60) then
                            matrix_addr(i) <= IEEE_802_11AD_P42_N672_R062_ADDR(i);
                            matrix_shift(i) <= IEEE_802_11AD_P42_N672_R062_OFFSET(i);
                        else
                            matrix_addr(i) <= -1;
                            matrix_shift(i) <= -1;
                        end if;
                    elsif (code_rate = R075) then
                        if (i < 60) then
                            matrix_addr(i) <= IEEE_802_11AD_P42_N672_R075_ADDR(i);
                            matrix_shift(i) <= IEEE_802_11AD_P42_N672_R075_OFFSET(i);
                        else
                            matrix_addr(i) <= -1;
                            matrix_shift(i) <= -1;
                        end if;
                    else 
                        if (i < 48) then
                            matrix_addr(i) <= IEEE_802_11AD_P42_N672_R081_ADDR(i);
                            matrix_shift(i) <= IEEE_802_11AD_P42_N672_R081_OFFSET(i);
                        else
                            matrix_addr(i) <= -1;
                            matrix_shift(i) <= -1;
                        end if;
                    end if;
                end loop;

                if (code_rate = R050) then
                    matrix_shifting_info <= IEEE_802_11AD_P42_N672_R050_SHIFTING_INFO;
                    matrix_last_row <= IEEE_802_11AD_P42_N672_R050_LAST_ROWS;
                    matrix_rows <= R050_ROWS;
                    matrix_max_check_degree <= MAX_CHECK_DEGREE_R050;
                elsif (code_rate = R062) then
                    matrix_shifting_info <= IEEE_802_11AD_P42_N672_R062_SHIFTING_INFO;
                    matrix_last_row <= IEEE_802_11AD_P42_N672_R062_LAST_ROWS;
                    matrix_rows <= R062_ROWS;
                    matrix_max_check_degree <= MAX_CHECK_DEGREE_R062;
                elsif (code_rate = R075) then
                    matrix_shifting_info <= IEEE_802_11AD_P42_N672_R075_SHIFTING_INFO;
                    matrix_last_row <= IEEE_802_11AD_P42_N672_R075_LAST_ROWS;
                    matrix_rows <= R075_ROWS;
                    matrix_max_check_degree <= MAX_CHECK_DEGREE_R075;
                else 
                    matrix_shifting_info <= IEEE_802_11AD_P42_N672_R081_SHIFTING_INFO;
                    matrix_last_row <= IEEE_802_11AD_P42_N672_R081_LAST_ROWS;
                    matrix_rows <= R081_ROWS;
                    matrix_max_check_degree <= MAX_CHECK_DEGREE_R081;
                end if;

                nx_state <= FIRST;

            --------------------------------------------------------------------------------------
            -- second state (VC and CF2)
            --------------------------------------------------------------------------------------
            when FIRST =>                   


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '0';
                ena_cf <= '0';


                if (first_time = true) then

                    ena_msg_ram <= '0';
                    ena_vc <= (others => '1');                             -- ENA_VC for the the first time it is in this state (writing to APP)
                                                                           -- sel_mux_input_halves <= '0';                            -- start with MS half
                    sel_mux_input_app <= '1';                               -- store in APP from input

                    app_wr_addr <= '0';                                     -- store in APP in first half

                    -- matrix's rows handling
                    cng_counter := 0;

                    -- iteration handling 
                    iter_int := 0;

                    -- message ram addresses
                    msg_row_rd := 0;
                    msg_row_wr := 0;

                    new_codeword <= '1';
                else

                    ena_msg_ram <= '1';

                    -- here should use the enables valid for the SECOND state
                    for i in 0 to CFU_PAR_LEVEL - 1 loop
                        ena_vc(i) <= ena_vc_second(i);
                    end loop;

                    app_rd_addr <= '0';
                    app_wr_addr <= '1';

                    sel_mux_input_app <= '0';

                    -- matrix's rows handling
                    cng_counter := cng_counter + 1;
                    if (cng_counter = matrix_rows) then
                        cng_counter := 0;

                        -- iteration handling 
                        iter_int := iter_int + 1;

                        -- ok_checks handling 
                        ok_checks := 0;

                        finish_iter <= '1';
                        monitor_finish_iter <= '1';

                    end if;

                    -- message ram addresses
                    if (msg_row_rd = matrix_rows * 2) then
                        msg_row_rd := 0;
                    end if;

                end if;



                --
                -- max_app_val or real app val + real shift AND ena_vc
                --
                -- first half
                vector_addr := cng_counter * matrix_max_check_degree;       -- base address for the matrix
                index_row := 0;
                for i in 0 to CFU_PAR_LEVEL - 1 loop                        --- maybe change order of loop if not storing in correct place
                    if (i = matrix_addr(index_row + vector_addr)) then            -- is the value in app or dummy value 
                        if (first_time = true) then
                            sel_mux_output_app(i) <= std_logic_vector(to_unsigned(2, sel_mux_output_app(0)'length));            
                        else
                            sel_mux_output_app(i) <= std_logic_vector(to_unsigned(0, sel_mux_output_app(0)'length));            
                        end if;
                        ena_vc_first(i) := '1';
                        shift(i) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                        index_row := index_row + 1;
                    else
                        ena_vc_first(i) := '0';
                        sel_mux_output_app(i) <= std_logic_vector(to_unsigned(1, sel_mux_output_app(0)'length));         -- put max_extr_msg
                        shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));                  -- it is indifferent how much we shift 
                    end if;
                end loop;

                start_pos_next_half := index_row;


                --
                -- inside CNB                 
                --
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));


                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));

                if (first_time = false) then
                    msg_row_wr := msg_row_wr + 1;
                end if;
                msg_row_rd := msg_row_rd + 1;

                for i in 0 to CFU_PAR_LEVEL - 1 loop
                    if (matrix_last_row(CFU_PAR_LEVEL + i) = current_row) then
                        shifting_info(i) <= std_logic_vector(to_unsigned(matrix_shifting_info(CFU_PAR_LEVEL + i), shifting_info(i)'length));
                    else
                        shifting_info(i) <= std_logic_vector(to_unsigned(0, shifting_info(i)'length));
                    end if;
                end loop;



                --
                -- next state
                --
                if (iter_int = MAX_ITER or next_iter_last_iter = true) then
                    if (next_iter_last_iter = true) then
                        valid_output <= '1';
                    end if;
                    finish_iter <= '1';
                    monitor_finish_iter <= '1';
                    new_codeword <= '0';
                    nx_state <= FINISH;
                else
                    nx_state <= SECOND;
                end if;


            --------------------------------------------------------------------------------------
            -- third state
            --------------------------------------------------------------------------------------
            when SECOND =>   -- store second half of codeword


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '1';
                ena_cf <= '0';
                ena_msg_ram <= '0';


                --
                -- APP RAM  or NEW_CODEWORD
                --
                if (first_time = true) then
                    -- sel_mux_input_halves <= '1';                -- get codeword from input 

                    ena_vc <= (others => '1');                  -- store second half in APP
                    sel_mux_input_app <= '1';                   -- store in APP from input second half

                    app_wr_addr <= '1';                         -- store in address 1 of APP

                    new_codeword <= '0';

                else
                    sel_mux_input_app <= '0';
                    ena_vc <= (others => '0');                  -- using APP values
                    app_rd_addr <= '1';

                    current_row := current_row + 1;
                    if (current_row = matrix_rows) then
                        current_row := 0;
                    end if;
                end if;


                -- 
                -- parity checks (1st half)
                --
                for i in 0 to SUBMAT_SIZE - 1 loop                      -- for each CNB
                    pchecks(i) := parity_out(i)(0);                     -- bit if edge 0, for cnb i
                    for j in 1 to CFU_PAR_LEVEL - 1 loop                -- xor all the edges (j) in each cnb (i)
                        pchecks(i) := pchecks(i) xor parity_out(i)(j);  
                    end loop;
                end loop;


                --
                -- max_app_val or real app val + real shift 
                --
                -- second half
                vector_addr := cng_counter * matrix_max_check_degree;
                index_row := start_pos_next_half;                   -- start from position in index where value is >= 8 (meaning second half start)
                for j in 0 to CFU_PAR_LEVEL - 1 loop        -- for all the APP rams
                    if index_row < matrix_max_check_degree then     -- if this is still part of this second half row of the matrix 
                        if (j + CFU_PAR_LEVEL = matrix_addr(index_row + vector_addr)) then        -- this value of the matrix corresponds to this app ram
                            if (first_time = true) then                       
                                sel_mux_output_app(j) <= std_logic_vector(to_unsigned(2, sel_mux_output_app(0)'length));                -- if first time, get it from input
                            else
                                sel_mux_output_app(j) <= std_logic_vector(to_unsigned(0, sel_mux_output_app(0)'length));                -- else, get it from cnb
                            end if;
                            ena_vc_second(j) := '1';
                            shift(j) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                            index_row := index_row + 1;
                        else 
                            ena_vc_second(j) := '0';
                            sel_mux_output_app(j) <= std_logic_vector(to_unsigned(1, sel_mux_output_app(0)'length));            
                            shift(j) <= std_logic_vector(to_unsigned(0, shift(0)'length));      
                        end if;
                    else
                        ena_vc_second(j) := '0';
                        sel_mux_output_app(j) <= std_logic_vector(to_unsigned(1, sel_mux_output_app(0)'length));            
                        shift(j) <= std_logic_vector(to_unsigned(0, shift(0)'length));      
                    end if;
                end loop;



                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_row_rd := msg_row_rd + 1;


                --
                -- next state
                --
                nx_state <= THIRD;



            --------------------------------------------------------------------------------------
            -- third state (CT and RP)
            --------------------------------------------------------------------------------------
            when THIRD =>          -- at first in CT


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '0';
                ena_ct <= '1';
                ena_cf <= '1';
                ena_msg_ram <= '0';
                ena_vc <= (others => '0');


                --
                -- APP RAM
                --
                -- nothing to do
                sel_mux_input_app <= '0';


                -- 
                -- parity checks (2st half)
                --
                for i in 0 to SUBMAT_SIZE - 1 loop
                    pchecks(i) := pchecks(i) xor parity_out(i)(0);
                    for j in 1 to CFU_PAR_LEVEL - 1 loop
                        pchecks(i) := pchecks(i) xor parity_out(i)(j);
                    end loop;
                end loop;

                for i in 0 to SUBMAT_SIZE - 1 loop
                    if (pchecks(i) = '0') then
                        val := 1;
                    else
                        val := 0;
                    end if;
                    ok_checks := ok_checks + val;
                end loop;


                -- if all parity checks are satisfied do one more whole iteration (EARLY TERMINATION)
                if (ok_checks = matrix_rows * SUBMAT_SIZE) then
                    next_iter_last_iter := true;
                end if;


                --
                -- max_app_val or real app val + real shift 
                --
                -- no shifting done because there's no data needed


                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));


                -- finish_iter
                finish_iter <= '0';
                monitor_finish_iter <= '0';


                --
                -- next state
                --
                nx_state <= FOURTH;




            --------------------------------------------------------------------------------------
            -- fourth state (just CF)
            --------------------------------------------------------------------------------------
            when FOURTH => 


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '0';
                ena_ct <= '0';
                ena_cf <= '1';
                ena_msg_ram <= '1';

                -- here should use the enables valid for the FIRST state
                for i in 0 to CFU_PAR_LEVEL - 1 loop
                    ena_vc(i) <= ena_vc_first(i);
                end loop;

                sel_mux_input_app <= '0';



                --
                -- APP RAM
                --
                app_wr_addr <= '0';

                first_time := false;

                --
                -- max_app_val or real app val + real shift 
                --
                -- no shifting done because there's no data needed
                -- reset if reached end
                if (msg_row_wr = matrix_rows * 2) then
                    msg_row_wr := 0;
                end if;


                for i in 0 to CFU_PAR_LEVEL - 1 loop
                    if (matrix_last_row(i) = current_row) then
                        shifting_info(i) <= std_logic_vector(to_unsigned(matrix_shifting_info(i), shifting_info(i)'length));
                    else
                        shifting_info(i) <= std_logic_vector(to_unsigned(0, shifting_info(i)'length));
                    end if;
                end loop;


                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));
                msg_row_wr := msg_row_wr + 1;



                --
                -- next state
                -- 
                nx_state <= FIRST;



            --------------------------------------------------------------------------------------
            -- last state (need to store 2nd half in output module)
            --------------------------------------------------------------------------------------
            when FINISH =>      -- when we have either reached maximum number of iterations or all pchks satisfied


                -- clock gating for pipeline stages
                ena_rp <= '0';
                ena_ct <= '0';
                ena_cf <= '0';
                ena_vc <= (others => '0');

                -- APP ram
                app_rd_addr <= '1';


                --
                -- max_app_val or real app val + real shift 
                --
                -- no shifting done because there's no data needed


                --
                -- inside CNB
                --
                -- not needed


                -- signal for output module
                finish_iter <= '1';
                monitor_finish_iter <= '1';
                new_codeword <= '0';

                -- next state 
                nx_state <= START_RESET;


        end case;

    end process;

end architecture circuit;
