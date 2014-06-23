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
             ena_vc: out std_logic;
             ena_rp: out std_logic;
             ena_ct: out std_logic;
             ena_cf: out std_logic;
             valid_output: out std_logic;
             iter: out t_iter;
             app_rd_addr: out std_logic;
             app_wr_addr: out std_logic;
             msg_rd_addr: out t_msg_ram_addr;
             msg_wr_addr: out t_msg_ram_addr;
             shift: out t_shift_contr;
             mux_input_halves: std_logic;           -- mux choosing input codeword halves
             mux_input_app: out std_logic;        -- mux at input of app rams used for storing (0 = CNB, 1 = new code)
             mux_output_app: out t_mux_out_app                    -- mux output of appram used for selecting input of CNB (0 = app, 1 = dummy, 2 = new_code)
         );
end entity controller;
--------------------------------------------------------
architecture circuit of controller is

    -- signals used in FSM
    type state is (START_RESET, START_STORE_FIRST_HALF, START_STORE_SECOND_HALF, CNB_INPUT_FULL, ITERATING_FIRST, ITERATING_SECOND, FINISHING_ITER);
    signal pr_state: state;
    signal nx_state: state;
    attribute enum_encoding: string;
    attribute enum_encoding of state: type is "sequential";

    -- signals used for typecasting

    -- signals used for keeping score of the number of layers checked so far
    -- signal num_layers: integer range 0 to MSG_RAM_DEPTH -1 := '0';


    -- signals used for handling parity check matrix 
    -- signal addr_vector: integer  := '0';
    signal addr_length: std_logic := '0';


    -- signals used for paritiy check matrix
    -- I'm choosing the biggest size of them and to address them I'm using the max check degree
    signal matrix_addr: t_array64 := (others => 0);      
    signal matrix_shift: t_array64 := (others => 0);
    signal matrix_length: natural range 0 to 64;
    signal matrix_rows: natural range 0 to 8:= 1;
    signal matrix_max_check_degree: natural range 0 to 16;

    -- iterating signal

    -- signals used for debugging (assigned by variables)
    signal index_row_sig: natural := 0;
    signal cng_counter_sig: natural := 0;
    signal vector_addr_sig: natural := 0;
    signal start_pos_next_half_sig: natural := 0;
    signal ok_checks_sig: integer := 0;
    
    
begin

    --------------------------------------------------------------------------------------
    -- selection of matrices depending on the code rate 
    --------------------------------------------------------------------------------------

    gen_matrix_addr: for i in 0 to 63 generate
        matrix_addr(i) <= IEEE_802_11AD_P42_N672_R050_ADDR(i) when code_rate = R050 else 
                          IEEE_802_11AD_P42_N672_R062_ADDR(i) when i < 60 else -1 when code_rate = R062 else
                          IEEE_802_11AD_P42_N672_R075_ADDR(i) when i < 60 else -1 when code_rate = R075 else
                          IEEE_802_11AD_P42_N672_R081_ADDR(i) when i < 48 else -1 when code_rate = R081;
    end generate gen_matrix_addr;


    -- changed to use offset matrix instead of original shift because of one permutation network
    gen_matrix_shift: for i in 0 to 63 generate
        matrix_shift(i) <= IEEE_802_11AD_P42_N672_R050_OFFSET(i) when code_rate = R050 else 
                           IEEE_802_11AD_P42_N672_R062_OFFSET(i) when i < 60 else -1 when code_rate = R062 else
                           IEEE_802_11AD_P42_N672_R075_OFFSET(i) when i < 60 else -1 when code_rate = R075 else
                           IEEE_802_11AD_P42_N672_R081_OFFSET(i) when i < 48 else -1 when code_rate = R081;
    end generate gen_matrix_shift;

    matrix_length <= IEEE_802_11AD_P42_N672_R050_ADDR'length when code_rate = R050 else
                     IEEE_802_11AD_P42_N672_R062_ADDR'length when code_rate = R062 else
                     IEEE_802_11AD_P42_N672_R075_ADDR'length when code_rate = R075 else
                     IEEE_802_11AD_P42_N672_R081_ADDR'length;

    matrix_rows <= R050_ROWS when code_rate = R050 else
                   R062_ROWS when code_rate = R062 else
                   R075_ROWS when code_rate = R075 else
                   R081_ROWS;

    matrix_max_check_degree <= matrix_length / matrix_rows;


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

        -- app rams
        variable app_rd_addr_var: std_logic := '0';
        variable app_wr_addr_var: std_logic := '1';

        -- base address of matrix (cng_counter * matrix_max_check_degree)
        variable vector_addr: integer range 0 to 64 := 0;

        -- row number in reduced matrix
        variable cng_counter: integer range 0 to 8 := 0;


        -- iteratons
        variable iter_int: integer range 0 to 10 := 0;
        variable last_row: boolean := false;
        variable last_iter: boolean := false;
        

        -- msg rams
        variable msg_row_rd: integer range 0 to 16 := 0;
        variable msg_row_wr: integer range 0 to 16 := 0;


        -- parity checks
        variable ok_checks: integer range 0 to 672/2:= 0;

        -- flushing
        variable flush_complete: boolean := false;

        -- aux
        variable val: integer range 0 to 1 := 0;
        
        -- start pos
        variable start_pos_next_half: integer range 0 to 64 := 0;
        variable indx: integer range 0 to 64 := 0;
        variable index_row: integer range 0 to 64 := 0;

        -- finish iterating
        variable finish: boolean := false;
        variable next_iter_last_iter: boolean := false;
        
        
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
                ena_vc <= '0';


                --
                -- App ram (NOT ENABLED)
                --
                mux_input_app <= '0';
                app_rd_addr_var := '0';
                app_wr_addr_var := '1';
                app_rd_addr <= '0';
                app_wr_addr <= '0';
                mux_input_halves <= '0';


                --
                -- max_app_val or real app val + real shift 
                --
                mux_output_app <= (others => (others => '0'));
                shift <= (others => (others => '0'));


                --
                -- inside CNB                 
                --

                msg_row_rd := 0;
                msg_row_wr := 0;
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));

                iter_int := 0;
                finish := false;
                iter <= std_logic_vector(to_unsigned(0, BW_MAX_ITER));


                --
                -- resetting valid output
                -- 
                ok_checks := 0;
                valid_output <= '0';


                --
                -- next state
                --
                nx_state <= START_STORE_FIRST_HALF;


            --------------------------------------------------------------------------------------
            -- second state 
            --------------------------------------------------------------------------------------

            when START_STORE_FIRST_HALF =>                   -- store first half of codeword/ new codeword


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '0';
                ena_cf <= '0';
                ena_vc <= '1';


                --
                -- App ram (NOT ENABLED)
                --
                mux_input_app <= '1';                               -- new codeword
                app_rd_addr <= '0';
                app_wr_addr <= '0';
                mux_input_halves <= '0';


                --
                -- max_app_val or real app val + real shift 
                --
                -- first half
                cng_counter := 0;                                           -- beginning the matrix
                vector_addr := cng_counter * matrix_max_check_degree;       -- base address for the matrix
                index_row := 0;
                for i in 0 to CFU_PAR_LEVEL - 1 loop                        --- maybe change order of loop if not storing in correct place
                                                                            -- if (matrix_addr(index_row + vector_addr) < 8) then                -- have we check entire first half row values?
                    if (index_row < matrix_max_check_degree / 2) then                -- have we check entire first half row values?
                        if (i = matrix_addr(index_row + vector_addr)) then            -- is the value in app or dummy value 
                            mux_output_app(i) <= std_logic_vector(to_unsigned(2, mux_output_app(0)'length));            
                            shift(i) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                            index_row := index_row + 1;
                        else
                            mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));         -- put max_extr_msg
                            shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));                  -- it is indifferent how much we shift 
                        end if;
                    else
                        mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));         -- put max_extr_msg
                        shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));                  -- it is indifferent how much we shift 
                    end if;
                end loop;

                start_pos_next_half := index_row;


                --
                -- inside CNB                 
                --
                iter <= std_logic_vector(to_unsigned(0, BW_MAX_ITER));
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_row_rd := msg_row_rd + 1;


                --
                -- signals for debugging
                --
                index_row_sig <= index_row;
                cng_counter_sig <= cng_counter;
                vector_addr_sig <= vector_addr;
                start_pos_next_half_sig <= start_pos_next_half;


                --
                -- next state
                --
                nx_state <= START_STORE_SECOND_HALF;



            --------------------------------------------------------------------------------------
            -- third state
            --------------------------------------------------------------------------------------
            when START_STORE_SECOND_HALF =>   -- store second half of codeword


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '1';
                ena_cf <= '0';
                ena_vc <= '1';


                --
                -- APP RAM (enabled for new codeword)
                --
                mux_input_app <= '1';                               -- new codeword
                app_rd_addr <= '1';
                app_wr_addr <= '1';
                mux_input_halves <= '1';


                --
                -- max_app_val or real app val + real shift 
                --
                -- second half
                vector_addr := cng_counter * matrix_max_check_degree;
                index_row := start_pos_next_half;                   -- start from position in index where value is >= 8 (meaning second half start)
                for j in 0 to CFU_PAR_LEVEL - 1 loop        -- for all the APP rams
                    if index_row < matrix_max_check_degree then     -- if this is still part of this second half row of the matrix 
                        if (j + CFU_PAR_LEVEL = matrix_addr(index_row + vector_addr)) then        -- this value of the matrix corresponds to this app ram
                            mux_output_app(j) <= std_logic_vector(to_unsigned(2, mux_output_app(0)'length));            
                            shift(j) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                            index_row := index_row + 1;
                        else 
                            mux_output_app(j) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                            shift(j) <= std_logic_vector(to_unsigned(0, shift(0)'length));      
                        end if;
                    -- else                                    -- for all the remaining APP rams put out dummy value
                    --     mux_output_app(j) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                    --     shift(j) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- it is indifferent how much we shift 
                    end if;
                end loop;

                cng_counter := cng_counter + 1;             -- next time start from next row(cng)


                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(0, BW_MAX_ITER));
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_row_rd := msg_row_rd + 1;


                --
                -- signals for debugging
                --
                index_row_sig <= index_row;
                cng_counter_sig <= cng_counter;
                vector_addr_sig <= vector_addr;
                start_pos_next_half_sig <= start_pos_next_half;


                --
                -- next state
                --
                nx_state <= CNB_INPUT_FULL;



            --------------------------------------------------------------------------------------
            -- third state
            --------------------------------------------------------------------------------------
            when CNB_INPUT_FULL =>          -- at first in CT

                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '1';
                ena_cf <= '1';
                ena_vc <= '0';


                --
                -- APP RAM
                --
                mux_input_app <= '0';
                app_rd_addr <= app_rd_addr_var;
                app_wr_addr <= app_wr_addr_var;


                --
                -- max_app_val or real app val + real shift 
                --
                -- first half
                vector_addr := cng_counter * matrix_max_check_degree;
                index_row := 0;
                for i in 0 to CFU_PAR_LEVEL - 1 loop            --- maybe change order of loop if not storing in correct place
                    -- if (matrix_addr(index_row + vector_addr) < 8) then       
                    if (index_row < matrix_max_check_degree / 2) then                -- have we check entire first half row values?
                        if (i = matrix_addr(index_row + vector_addr)) then            -- is the value in app or is dummy value? 
                            mux_output_app(i) <= std_logic_vector(to_unsigned(0, mux_output_app(0)'length));            
                            shift(i) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                            index_row := index_row + 1;
                        else
                            mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                            shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- it is indifferent how much we shift 
                        end if;
                    else
                        mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                        shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- it is indifferent how much we shift 
                    end if;
                end loop;

                start_pos_next_half := index_row;


                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(0, BW_MAX_ITER));
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));
                msg_row_rd := msg_row_rd + 1;
                msg_row_wr := msg_row_wr + 1;


                --
                -- signals for debugging
                --
                index_row_sig <= index_row;
                cng_counter_sig <= cng_counter;
                vector_addr_sig <= vector_addr;
                start_pos_next_half_sig <= start_pos_next_half;


                --
                -- next state
                --
                nx_state <= ITERATING_FIRST;


            --------------------------------------------------------------------------------------
            -- four state (whole datapath is full)
            --------------------------------------------------------------------------------------
            when ITERATING_FIRST =>            -- first half is being written back to app CF


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '1';
                ena_cf <= '1';
                ena_vc <= '1';


                --
                -- APP RAM
                --
                mux_input_app <= '0';

                app_rd_addr_var := not app_rd_addr_var;
                app_rd_addr <= app_rd_addr_var;

                app_wr_addr_var := not app_wr_addr_var;
                app_wr_addr <= app_wr_addr_var;


                --
                -- max_app_val or real app val + real shift 
                --
                -- second half
                vector_addr := cng_counter * matrix_max_check_degree;   -- base address of row
                index_row := start_pos_next_half;                   -- start from position in index where value is >= 8 (meaning second half start)
                for j in 0 to CFU_PAR_LEVEL - 1 loop        -- for all the APP rams
                    if (index_row < matrix_max_check_degree) then     -- if this is still part of this second half row of the matrix 
                        if (j + CFU_PAR_LEVEL = matrix_addr(index_row + vector_addr)) then        -- this value of the matrix corresponds to this app ram
                            mux_output_app(j) <= std_logic_vector(to_unsigned(0, mux_output_app(0)'length));            
                            shift(j) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));        
                            index_row := index_row + 1;
                        else 
                            mux_output_app(j) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                            shift(j) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- because the matrix has the same values it is indifferent how much we shift 
                        end if;
                    end if;
                end loop;


                -- increment row in addr matrix. check if we have reached the last row of the addr matrix and if true then reset it to the first row
                cng_counter := cng_counter + 1;
                if (cng_counter = matrix_rows) then
                    cng_counter := 0;
                    last_row := true;
                end if;

                -- if we are in the last row and this is our last iteration then we're finished iterating with this codeword
                -- if (msg_row_wr = matrix_rows * 2 - 1 and last_iter = true) then
                --     finish := true;
                -- end if;


                --
                -- Parity checks handling
                --
                -- parity_out out of CN, which happens every 2 cycles in CT stage in the pipeline, we add and accumulate the parity_check
                for i in 0 to SUBMAT_SIZE - 1 loop
                    if (parity_out(i) = '0') then
                        val := 1;
                    else
                        val := 0;
                    end if;
                    ok_checks := ok_checks + val;
                end loop;

                -- if all parity checks are satisfied do one more whole iteration
                if (ok_checks = matrix_rows * SUBMAT_SIZE) then
                    if (next_iter_last_iter = true) then
                        finish := true;
                    else
                        next_iter_last_iter := true;
                    end if;
                end if;


                --
                -- inside CNB
                --
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));

                -- increment row in msg ram and restart from the beginning if we have reached the end (and also set last_iter := next_iter_last iter for msg_row_wr)
                msg_row_rd := msg_row_rd + 1;
                msg_row_wr := msg_row_wr + 1;

                if (msg_row_rd = matrix_rows * 2) then
                    msg_row_rd := 0;
                end if;
                if (msg_row_wr = matrix_rows * 2) then
                    msg_row_wr := 0;
                end if;
                

                -- reset ok checks only if we keep iterating else we need it to set "valid" signal
                if (msg_row_wr = 0 and finish = false) then
                    ok_checks := 0;
                end if;


                --
                -- signals for debugging
                --
                index_row_sig <= index_row;
                cng_counter_sig <= cng_counter;
                vector_addr_sig <= vector_addr;
                start_pos_next_half_sig <= start_pos_next_half;
                ok_checks_sig <= ok_checks;

                if (last_iter = true and msg_row_wr = 0) then
                    --statement
                end if;

                --
                -- next state 
                --
                if (finish) then
                    if (ok_checks = matrix_rows * SUBMAT_SIZE) then
                       valid_output <= '1';
                    end if;
                    nx_state <= FINISHING_ITER;
                else
                    nx_state <= ITERATING_SECOND;
                end if;


            --------------------------------------------------------------------------------------
            -- iterating and outputing second half
            --------------------------------------------------------------------------------------
            when ITERATING_SECOND =>                -- second half is being written back to app CF2

                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '1';
                ena_ct <= '1';
                ena_cf <= '1';
                ena_vc <= '1';


                --
                -- APP RAM
                --
                mux_input_app <= '0';

                app_rd_addr_var := not app_rd_addr_var;
                app_rd_addr <= app_rd_addr_var;

                app_wr_addr_var := not app_wr_addr_var;
                app_wr_addr <= app_wr_addr_var;


                --
                -- max_app_val or real app val + real shift 
                --
                -- first half
                vector_addr := cng_counter * matrix_max_check_degree;   -- base address of row
                index_row := 0;
                for i in 0 to CFU_PAR_LEVEL - 1 loop            --- maybe change order of loop if not storing in correct place
                    -- if (matrix_addr(index_row + vector_addr) < 8) then       
                    if (index_row < matrix_max_check_degree / 2) then                -- have we check entire first half row values?
                        if (i = matrix_addr(index_row + vector_addr)) then            -- if the value of matrix isn't this 1 but it's not at the end of it
                            mux_output_app(i) <= std_logic_vector(to_unsigned(0, mux_output_app(0)'length));            
                            shift(i) <= std_logic_vector(to_unsigned(matrix_shift(index_row + vector_addr), shift(0)'length));
                            index_row := index_row + 1;
                        else
                            mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                            shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- it is indifferent how much we shift 
                        end if;
                    else
                        mux_output_app(i) <= std_logic_vector(to_unsigned(1, mux_output_app(0)'length));            
                        shift(i) <= std_logic_vector(to_unsigned(0, shift(0)'length));   -- it is indifferent how much we shift 
                    end if;
                end loop;

                start_pos_next_half := index_row;


                --
                -- inside CNB
                --

                -- iteration handling 
                if (last_row = true) then
                    last_row := false;
                    iter_int := iter_int + 1;
                    if (iter_int = 9) then
                        last_iter := true;
                    end if;
                end if;
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));

                
                -- set all msg address for next cycle
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));
                -- increment row in msg ram and restart if we have past the end
                msg_row_rd := msg_row_rd + 1;
                msg_row_wr := msg_row_wr + 1;


                --
                -- signals for debugging
                --
                index_row_sig <= index_row;
                cng_counter_sig <= cng_counter;
                vector_addr_sig <= vector_addr;
                start_pos_next_half_sig <= start_pos_next_half;
                ok_checks_sig <= ok_checks;


                --
                -- next state 
                --
                nx_state <= ITERATING_FIRST;
                


            --------------------------------------------------------------------------------------
            -- we have to let the pipeline flush itself out
            --------------------------------------------------------------------------------------
            when FINISHING_ITER =>      -- when we have either reached maximum number of iterations or all pchks satisfied


                --
                -- clock gating for pipeline stages
                --
                ena_rp <= '0';
                ena_ct <= '0';
                ena_cf <= '1';
                ena_vc <= '1';


                --
                -- APP ram
                -- 
                mux_input_app <= '0';

                app_rd_addr_var := not app_rd_addr_var;
                app_rd_addr <= app_rd_addr_var;

                app_wr_addr_var := not app_wr_addr_var;
                app_wr_addr <= app_wr_addr_var;


                --
                -- max_app_val or real app val + real shift 
                -- 
                -- doesn't matter
                mux_output_app <= (others => (others => '0'));
                shift <= (others => (others => '0'));


                --
                -- inside CNB
                --
                -- doesn't matter
                msg_rd_addr <= std_logic_vector(to_unsigned(msg_row_rd, BW_MSG_RAM));
                msg_wr_addr <= std_logic_vector(to_unsigned(msg_row_wr, BW_MSG_RAM));


                --
                -- Parity checks handling
                --
                valid_output <= '1';
                next_iter_last_iter := false;
                last_iter := false;


                --
                -- iteration handling 
                --
                iter_int := 0;
                iter <= std_logic_vector(to_unsigned(iter_int, BW_MAX_ITER));


                --
                -- next state 
                --
                nx_state <= START_RESET;

        end case;

    end process;

end architecture circuit;
