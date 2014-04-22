--!
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file   check_node.vhd
--! @brief  Check node unit
--! @author Philipp Schläfer
--! @date   2013/02/02
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_support_global.all;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_types.all;
use work.pkg_support.all;
use work.pkg_check_node.all;
-- use work.pkg_components.all;


entity check_node is
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
end check_node;


architecture rtl_cfu of check_node is

	-- input signs
	signal data_in_sign : std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
	signal data_in_mag : t_mag_array;

	-- sorter signals
	signal sort_in  : t_sort_in_array;
	signal sort_out : t_sort_out_array;

	-- Minimum out of four input / output signals
	signal four_min_s1_in  : t_four_min_s1_in_array;
	signal four_min_s2_in  : t_four_min_s2_in_array;
	signal four_min_s3_in  : t_four_min_s3_in_array;
	signal four_min_s1_out : t_four_min_s1_out_array;
	signal four_min_s2_out : t_four_min_s2_out_array;
	signal four_min_s3_out : t_four_min_s3_out_array;

	signal data_out_neg_tc : t_four_min_s2_out_array_tc;
	signal data_out_pos_tc : t_four_min_s2_out_array_tc;

	-- Index of the evaluated minimum
	signal index_s2 : t_index;
	signal index_s3 : unsigned(3 downto 0); -- TODO define a const
	-- signal index_s2_reg : t_index;
	signal index_s2_i : t_index;
	signal index_h : unsigned(3 downto 0);
	signal index_l : unsigned(3 downto 0);

	-- Parity calculation signals
	-- signal parity_s0 : std_logic_vector(7 downto 0);
	-- signal parity_s1 : std_logic_vector(3 downto 0);
	-- signal parity_s2 : std_logic_vector(1 downto 0);
	-- signal parity_s3 : std_logic;

    signal parity_s0 : std_logic_vector(3 downto 0);
	signal parity_s1 : std_logic_vector(1 downto 0);
	signal parity_s2 : std_logic;
	signal parity_s3 : std_logic;


	signal parity_h : std_logic;
	signal parity_l : std_logic;

	-- signal data_out_mag : t_four_min_s2_out_array;
	signal data_out_mag : t_four_min_s1_out_array;
	-- signal data_out_mag_scaled : t_four_min_s2_out_array;
	signal data_out_mag_scaled : t_four_min_s1_out_array;

	-- in- and output messages which are registered if specified
	signal data_in_i : t_cn_message;
	signal data_out_i : t_cn_message;

	-- intermediate register messages
	signal four_min_s2_out_i : t_four_min_s2_out_array;

	signal parity_s2_reg : std_logic_vector(1 downto 0);
	signal parity_s2_i : std_logic_vector(1 downto 0);

	signal split_reg : std_logic;
	signal split_i : std_logic;
	signal split_reg2 : std_logic;
	signal split_i2 : std_logic := '0';

	-- in- and output message registers
	signal data_in_reg : t_cn_message;
	signal data_out_reg : t_cn_message;
	signal data_in_sign_reg :std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
	signal data_in_sign_i : std_logic_vector(CFU_PAR_LEVEL - 1 downto 0);
	signal data_in_mag_reg : t_mag_array;
	signal data_in_mag_i : t_mag_array;

    -- intermediate message
    signal four_min_s2_out_first_half : t_four_min_s2_out_array;
    signal four_min_s2_out_first_half_reg: t_four_min_s2_out_array;

    signal index_s2_first_half: unsigned(3 downto 0);
    signal index_s2_first_half_reg: unsigned(3 downto 0);
    -- signal index_s2_reg: t_index;

    signal parity_s3_in_first_half: std_logic;
    signal parity_s3_in_first_half_reg: std_logic;

    signal first: std_logic := '0';

    signal parity_s3_out_mux: std_logic;
    signal parity_s3_out_reg: std_logic;

    signal data_out_mag_out_mux: t_four_min_s1_out_array;
    signal data_out_mag_out_reg: t_four_min_s1_out_array;

    signal data_out_pos_tc_out_mux: t_four_min_s2_out_array_tc;
    signal data_out_pos_tc_out_reg: t_four_min_s2_out_array_tc;
    

    signal data_out_neg_tc_out_mux: t_four_min_s2_out_array_tc;
    signal data_out_neg_tc_out_reg: t_four_min_s2_out_array_tc;
    
    
    
    

begin


    
    -- put registers (as flip flop) in the position where they correspond with the different stages of the pipeline
    -- change all widths to cover just half a row
    -- add the part where we store the first half of the layer minimus and index and sign in a register to wait for the other half and get the global mmin and sign and index.

	--
	-- concurrent assignments
	--

	-- split the sing from magnitude
	gen_input_sign_mag : for i in 0 to (CFU_PAR_LEVEL - 1) generate
		data_in_sign(i) <= data_in(i)(BW_EXTR - 1);
		-- data_in_mag(i) <= unsigned(data_in(i)(BW_EXTR - 2 downto 0));
		data_in_mag(i) <= unsigned(get_magnitude(data_in(i)));
	end generate;

    process (clk)
        --declarativepart
    begin
        if (clk'event and clk = '1') then
            data_in_mag_i <= data_in_mag;
            data_in_sign_i <= data_in_sign;
        end if;
    end process;

	-- prepare magnitude of input data for the sorters
	gen_sort_in : for i in 0 to (CFU_PAR_LEVEL/2 - 1) generate
		sort_in(i).min0 <= data_in_mag(2*i);
		sort_in(i).min1 <= data_in_mag(2*i+1);
	end generate;

	-- evaluate sorters
	gen_sort_out : for i in 0 to (CFU_PAR_LEVEL/2 - 1) generate
		sort_out(i) <= sort(sort_in(i));
	end generate;

	-- prepare input data for the first stage of four min modules
	gen_four_min_s1_in : for i in 0 to (CFU_PAR_LEVEL/4 - 1) generate
		four_min_s1_in(i).min0 <= sort_out(2*i).min0;
		four_min_s1_in(i).min1 <= sort_out(2*i).min1;
		four_min_s1_in(i).min2 <= sort_out(2*i+1).min0;
		four_min_s1_in(i).min3 <= sort_out(2*i+1).min1;
	end generate;

	-- evaluate the first stage of four min modules
	gen_four_min_s1_out : for i in 0 to (CFU_PAR_LEVEL/4 - 1) generate
		four_min_s1_out(i) <= four_min(four_min_s1_in(i));
	end generate;

	-- -- prepare input data for the second stage of four min modules
	-- gen_four_min_s2_in : for i in 0 to (CFU_PAR_LEVEL/8 - 1) generate
	-- 	four_min_s2_in(i).min0 <= four_min_s1_out(2*i).min0;
	-- 	four_min_s2_in(i).min1 <= four_min_s1_out(2*i).min1;
	-- 	four_min_s2_in(i).min2 <= four_min_s1_out(2*i+1).min0;
	-- 	four_min_s2_in(i).min3 <= four_min_s1_out(2*i+1).min1;
	-- end generate;
    --
	-- -- evaluate the second stage of four min modules
	-- gen_four_min_s2_out : for i in 0 to (CFU_PAR_LEVEL/8 - 1) generate
	-- 	four_min_s2_out(i) <= four_min(four_min_s2_in(i));
	-- end generate;


	-- prepare input data for the second stage of four min modules
	four_min_s2_in(0).min0 <= four_min_s1_out(0).min0;
	four_min_s2_in(0).min1 <= four_min_s1_out(0).min1;
	four_min_s2_in(0).min2 <= four_min_s1_out(0+1).min0;
	four_min_s2_in(0).min3 <= four_min_s1_out(0+1).min1;

	-- evaluate the second stage of four min modules
	four_min_s2_out(0) <= four_min(four_min_s2_in(0));

    
    -- connection between the output of register with first half check node info and the third (and last) stage of four min modules
    four_min_s2_out_first_half <= four_min_s2_out_first_half_reg;
    
    -- register storing first half row check node info
    process (clk)
    begin
        if (clk'event and clk = '1') then
            four_min_s2_out_first_half_reg <= four_min_s2_out;
        end if;
    end process;

    -- prepare input data for the third stage of the four min modules with the two halves row info
    four_min_s3_in(0).min0 <= four_min_s2_out_first_half(0).min0;
    four_min_s3_in(0).min1 <= four_min_s2_out_first_half(0).min1;
    four_min_s3_in(0).min2 <= four_min_s2_out(0).min0;
    four_min_s3_in(0).min3 <= four_min_s2_out(0).min0;

    -- evalue the third stage of the four min modules with the two halves rows info
    four_min_s3_out(0) <= four_min(four_min_s3_in(0));


    --
	-- Generate the index of the first minima
    --

    -- generating the index of first minima of first half row 
	index_s2(0) <= to_unsigned( 0, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '0' and sort_out(0).index = '0' else
	               to_unsigned( 1, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '0' and sort_out(0).index = '1' else
	               to_unsigned( 2, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '1' and sort_out(1).index = '0' else
	               to_unsigned( 3, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '1' and sort_out(1).index = '1' else
	               to_unsigned( 4, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '0' and sort_out(2).index = '0' else
	               to_unsigned( 5, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '0' and sort_out(2).index = '1' else
	               to_unsigned( 6, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '1' and sort_out(3).index = '0' else
	               to_unsigned( 7, 4);-- when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '1' and sort_out(3).index = '1';


    -- connection between output of register with index of first half and the last mux stage of index selection
    index_s2_first_half <= index_s2_first_half_reg;

    -- register storing first half row index  
    process (clk)
    begin
        if (clk'event and clk = '1') then
            index_s2_first_half_reg <= index_s2(0);
        end if;
    end process;


    -- generating the index of the first minima of second half row
	-- index_s2(1) <= to_unsigned( 8, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '0' and sort_out(0).index = '0' else
	--                to_unsigned( 9, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '0' and sort_out(0).index = '1' else
	--                to_unsigned(10, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '1' and sort_out(1).index = '0' else
	--                to_unsigned(11, 4) when four_min_s2_out(0).index = '0' and four_min_s1_out(0).index = '1' and sort_out(1).index = '1' else
	--                to_unsigned(12, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '0' and sort_out(2).index = '0' else
	--                to_unsigned(13, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '0' and sort_out(2).index = '1' else
	--                to_unsigned(14, 4) when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '1' and sort_out(3).index = '0' else
	--                to_unsigned(15, 4);-- when four_min_s2_out(0).index = '1' and four_min_s1_out(1).index = '1' and sort_out(3).index = '1';

	index_s3 <= index_s2_first_half when four_min_s3_out(0).index = '0' else
	            index_s2(0) + to_unsigned(8, 4);

	--
	-- Generate the parity check for the check node.
	-- It is represented by the following xor tree.
	--

	-- Evaluate first stage of xor
	gen_parity_s0 : for i in 0 to (CFU_PAR_LEVEL/2 - 1) generate
		parity_s0(i) <= data_in(2*i)(BW_EXTR - 1) xor data_in(2*i+1)(BW_EXTR - 1);
	end generate;

	-- Evaluate second stage of xor
	gen_parity_s1 : for i in 0 to (CFU_PAR_LEVEL/4 - 1) generate
		parity_s1(i) <= parity_s0(2*i) xor parity_s0(2*i+1);
	end generate;

	-- Evaluate third stage of xor
	-- gen_parity_s2 : for i in 0 to (CFU_PAR_LEVEL/8 - 1) generate
	-- 	parity_s2(i) <= parity_s1(2*i) xor parity_s1(2*i+1);
	-- end generate;

	-- Evaluate third stage of xor
	parity_s2 <= parity_s1(0) xor parity_s1(1);


    -- connection between output of register holding first half row parity check and last xor stage input
    parity_s3_in_first_half <= parity_s3_in_first_half_reg;

    -- sotre first half row check_node_info parity check
    process (clk)
        --declarativepart
    begin
        if (clk'event and clk = '1') then
            parity_s3_in_first_half_reg <= parity_s2;
        end if;
    end process;

    -- evaluate fourth stage of xor
    parity_s3 <= parity_s3_in_first_half xor parity_s2;

	-- Use parity s2 as output even if we are not in split mode.
	-- This is ok for now, but may be changed later.
	parity_out <= parity_s2_i;

    
    -------------------------------------------------------------------------------
    -- mux for selecting whether to use last cycle signal(for 2nd halves) or current cycle signals (for 1st halves)
    -------------------------------------------------------------------------------
    parity_s3_out_mux <= parity_s3 when count = 0 else parity_s3_out_reg;
    -- data_out_pos_tc_out_mux <= data_out_pos_tc when count = 0 else data_out_pos_tc_out_reg;
    -- data_out_neg_tc_out_mux <= data_out_neg_tc when count = 0 else data_out_neg_tc_out_reg;
    index_s3_out_mux <= index_s3 when count = 0 else index_s3_out_reg;
    -- data_out_mag_out_mux <= data_out_mag when count = 0 else data_out_mag_out_reg;
    four_min_s3_out_out_mux <= four_min_s3_out when count = 0 else four_min_s3_out_reg;


    -------------------------------------------------------------------------------
    -- counter used for select signal in multiplexer
    -------------------------------------------------------------------------------
    process (clk)
        variable count_var: integer 0 to 2 := 0;
    begin
        if (clk'event and clk = '1') then
            if (first = '0') then
                first <= '1';
            else
                count_var := count_var + 1;
                if (count_var = 2) then
                    count_var := 0;
                end if;
            end if;
        end if;
        count <= count_var;
    end process;

    
    -------------------------------------------------------------------------------
    -- registers for storing the minimums and paritys of the row for the second half
    -------------------------------------------------------------------------------
    process (clk)
    begin
        if (clk'event and clk = '1') then
            data_out_pos_tc_out_reg <= data_out_pos_tc_out_mux;
            data_out_neg_tc_out_reg <= data_out_neg_tc_out_mux;
            parity_s3_out_reg <= parity_s3_out_mux;
            index_s3_out_reg <= index_s3_out_mux;
            data_out_mag_out_reg <= data_out_mag_out_mux;
        end if;
    end process;



	--
	-- The following part handles the output.
	-- Depending on the operation mode, different result registers have to be used.
	--
    
    -- leave this like this because split is not used so output will always be four_min_s3_out
	pr_split : process(split_i2, parity_s2_i, parity_s3_out_mux, four_min_s2_out_i, four_min_s3_out_out_mux, index_s2_i, index_s3_out_mux)
	begin
		if split_i2 = '1' then
			data_out_mag(0) <= four_min_s2_out_i(0);
			parity_h <= parity_s2_i(0);
			index_h <= index_s2_i(0);
		else
			data_out_mag(0) <= four_min_s3_out_out_mux(0);
			parity_h <= parity_s3_out_mux;
			index_h <= index_s3_out_mux;
		end if;
		if split_i2 = '1' then
			-- data_out_mag(1) <= four_min_s2_out_i(1);
			parity_l <= parity_s2_i(1);
			index_l <= index_s2_i(1);
		else
			data_out_mag(1) <= four_min_s3_out_out_mux(0);
			parity_l <= parity_s3_out_mux;
			index_l <= index_s3_out_mux;
		end if;
	end process pr_split;

	data_out_mag_scaled(0).min0 <= esf_scale(data_out_mag(0).min0);
	data_out_mag_scaled(0).min1 <= esf_scale(data_out_mag(0).min1);
	data_out_mag_scaled(1).min0 <= esf_scale(data_out_mag(1).min0);
	data_out_mag_scaled(1).min1 <= esf_scale(data_out_mag(1).min1);

	-- Generate a positive and a negative tc variante
	data_out_neg_tc(0).min0 <= twos_comp_neg(data_out_mag_scaled(0).min0);
	data_out_neg_tc(0).min1 <= twos_comp_neg(data_out_mag_scaled(0).min1);
	data_out_neg_tc(1).min0 <= twos_comp_neg(data_out_mag_scaled(1).min0);
	data_out_neg_tc(1).min1 <= twos_comp_neg(data_out_mag_scaled(1).min1);
	data_out_pos_tc(0).min0 <= signed('0' & data_out_mag_scaled(0).min0);
	data_out_pos_tc(0).min1 <= signed('0' & data_out_mag_scaled(0).min1);
	data_out_pos_tc(1).min0 <= signed('0' & data_out_mag_scaled(1).min0);
	data_out_pos_tc(1).min1 <= signed('0' & data_out_mag_scaled(1).min1);

    -- Upper tree
    gen_out_upper : for i in 0 to (CFU_PAR_LEVEL/2 - 1) generate
        pr_gen_out_upper : process(parity_h, data_in_sign_i, data_out_mag, data_out_pos_tc, data_out_neg_tc, data_in_mag_i, index_h, index_l)
            variable v_sign : std_logic;
        begin
            v_sign := parity_h xor data_in_sign_i(i);
            if data_in_mag_i(i) = data_out_mag(0).min0 then
                -- 			if index_h = i then
                if v_sign = '1' then
                    data_out(i) <= data_out_neg_tc(0).min1;
                else
                    data_out(i) <= data_out_pos_tc(0).min1;
                end if;
            else
                if v_sign = '1' then
                    data_out(i) <= data_out_neg_tc(0).min0;
                else
                    data_out(i) <= data_out_pos_tc(0).min0;
                end if;
            end if;
        end process pr_gen_out_upper;
    end generate;

    -- Upper tree
    -- gen_out_upper : for i in 0 to (CFU_PAR_LEVEL/2 - 1) generate
    --     pr_gen_out_upper : process(parity_h, data_in_sign_i, data_out_mag, data_out_pos_tc, data_out_neg_tc, data_in_mag_i, index_h, index_l)
    --         variable v_sign : std_logic;
    --     begin
    --         v_sign := parity_h xor data_in_sign_i(i);
    --         if data_in_mag_i(i) = data_out_mag(0).min0 then
    --             -- 			if index_h = i then
    --             if v_sign = '1' then
    --                 data_out(i) <= data_out_neg_tc(0).min1;
    --             else
    --                 data_out(i) <= data_out_pos_tc(0).min1;
    --             end if;
    --         else
    --             if v_sign = '1' then
    --                 data_out(i) <= data_out_neg_tc(0).min0;
    --             else
    --                 data_out(i) <= data_out_pos_tc(0).min0;
    --             end if;
    --         end if;
    -- 	end process pr_gen_out_upper;
    -- end generate;


    -- Lower tree
    gen_out_lower : for i in (CFU_PAR_LEVEL/2) to (CFU_PAR_LEVEL - 1) generate
        pr_gen_out_lower : process(parity_l, data_in_sign_i, data_in_mag_i, data_out_pos_tc, data_out_neg_tc, data_out_mag, index_h, index_l)
            variable v_sign : std_logic;
        begin
            v_sign := parity_l xor data_in_sign_i(i);           -- calculate sign of this output considering parity sign and input sign
            if data_in_mag_i(i) = data_out_mag(1).min0 then     -- is this input the min0?
                                                                -- 			if index_l = i then
                if v_sign = '1' then
                    data_out(i) <= data_out_neg_tc(1).min1;
                else
                    data_out(i) <= data_out_pos_tc(1).min1;
                end if;
            else
                if v_sign = '1' then
                    data_out(i) <= data_out_neg_tc(1).min0;
                else
                    data_out(i) <= data_out_pos_tc(1).min0;
                end if;
            end if;
        end process pr_gen_out_lower;
    end generate;


end architecture rtl_cfu;
