--!
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file   pkg_check_node.vhd
--! @brief  Check node unit types and functions
--! @author Philipp Schläfer
--! @date   2012/02/02
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_types.all;


package pkg_check_node is


	-- input magnitude
	type t_mag_array is array(CFU_PAR_LEVEL - 1 downto 0) of unsigned(BW_EXTR - 2 downto 0);

	-- sorter input
	type trec_sort_in is record
		min0    : unsigned(BW_EXTR - 2 downto 0);
		min1    : unsigned(BW_EXTR - 2 downto 0);
	end record;

	-- array of sorter inputs
	type t_sort_in_array is array (CFU_PAR_LEVEL/2 - 1 downto 0) of trec_sort_in;

	-- sorter and compare select unit output
	type trec_min_out is record
		min0    : unsigned(BW_EXTR - 2 downto 0);
		min1    : unsigned(BW_EXTR - 2 downto 0);
		index   : std_logic;
	end record;

	-- twos complement converted minima
	type trec_min_out_tc is record
		min0    : signed(BW_EXTR - 1 downto 0);
		min1    : signed(BW_EXTR - 1 downto 0);
		index   : std_logic;
	end record;

	-- array of sorter outputs
	type t_sort_out_array is array (CFU_PAR_LEVEL/2 - 1 downto 0) of trec_min_out;

	-- Four min input array
	type trec_min_in is record
		min0    : unsigned(BW_EXTR - 2 downto 0);
		min1    : unsigned(BW_EXTR - 2 downto 0);
		min2    : unsigned(BW_EXTR - 2 downto 0);
		min3    : unsigned(BW_EXTR - 2 downto 0);
	end record;

	-- array of four min inputs
	type t_four_min_s1_in_array is array (1 downto 0) of trec_min_in;
	type t_four_min_s2_in_array is array (0 downto 0) of trec_min_in;
	type t_four_min_s3_in_array is array (0 downto 0) of trec_min_in;

	-- array of four min results
	type t_four_min_s1_out_array is array (1 downto 0) of trec_min_out;
	type t_four_min_s2_out_array is array (0 downto 0) of trec_min_out;
	type t_four_min_s3_out_array is array (0 downto 0) of trec_min_out;

	type t_four_min_s2_out_array_tc is array (1 downto 0) of trec_min_out_tc;
	type t_four_min_s3_out_array_tc is array (0 downto 0) of trec_min_out_tc;
	-- type t_four_min_s2_out_array_tc is array (0 downto 0) of trec_min_out_tc;

	type t_index is array (1 downto 0) of unsigned(3 downto 0); -- TODO use parameter

	--
	-- Functions
	--

	function esf_scale(val : unsigned) return unsigned;

	-- Comparator with two inputs
	function sort(data : trec_sort_in) return trec_min_out;

	function four_min(data : trec_min_in) return trec_min_out;
	function four_min_extra_comp(compare : trec_min_in; data : trec_min_in) return trec_min_out;


    -- addition by AJGP
    function get_magnitude(input : signed) return signed;

end pkg_check_node;


package body pkg_check_node is

    -- addition by AJGP
    function get_magnitude(input : signed) return signed is
        variable temp: signed(input'high downto input'low) := input;
    begin
        if (input(input'left) = '0') then
            return temp(temp'high-1 downto temp'low);
            -- return unsigned(input(input'high-1 downto input'low));
        else
            temp := temp - 1;
            for i in input'range loop
                temp(i) := not temp(i);
            end loop;
            return temp(temp'high-1 downto temp'low);
        end if;
    end function get_magnitude;


	-- scale minimum by the esf factor 0.875
	function esf_scale(val : unsigned) return unsigned is
		variable v_a1 : unsigned(val'high + 1 downto 0);
		variable v_a2 : unsigned(val'high + 1 downto 0);
		variable v_b1 : unsigned(val'high + 2 downto 0);
		variable v_b2 : unsigned(val'high + 2 downto 0);
		variable v_c  : unsigned(val'high downto 0);
	begin
		v_a1 := val & '1';                             -- 2 * input + 1 (+ 1 for up rounding)
		if ESF_0_875 = 1 then
			v_a2 := shift_right(val, 1) + ('0' & val); -- 1 * input + 0.5 * input
		else
			v_a2 := '0' & val;                         -- 1 * input
		end if;
		v_b1 := ('0' & v_a1) + v_a2;                       -- 3 * input (for ESF = 0.75)
		v_b2 := shift_right(v_b1, 2);                    -- 3 / 4 * input
		v_c  := v_b2(val'high downto 0);
		return v_c;
	end function;

	--
	-- FIXME TODO
	-- This version is no more fully correct!
	-- But it uses narrower adders.
	-- If compared with sw results this will differ!
	--
-- 	function esf_scale(val : unsigned) return unsigned is
-- 		variable v_a1 : unsigned(val'high + 1 downto 0);
-- 		variable v_a2 : unsigned(val'high + 1 downto 0);
-- 		variable v_b1 : unsigned(val'high + 1 downto 0);
-- 		variable v_b2 : unsigned(val'high + 1 downto 0);
-- 		variable v_c  : unsigned(val'high downto 0);
-- 	begin
-- 		v_a1 := '0' & shift_right(val, 1);               -- 1 / 2 * input
-- 		v_a2 := '0' & val;                         -- 1 * input
-- 		v_b1 := v_a1 + v_a2;                       -- 1.5 * input (for ESF = 0.75)
-- 		v_b2 := shift_right(v_b1, 1);              -- 1.5 / 2 * input
-- 		v_c  := v_b2(val'high downto 0);
-- 		return v_c;
-- 	end function;

	-- Sorter function reading two inputs
	function sort(data : trec_sort_in) return trec_min_out is
		variable v_res : trec_min_out;
	begin
		if data.min0 <= data.min1 then
			v_res.min0    := data.min0;
			v_res.index   := '0';
			v_res.min1    := data.min1;
		else
			v_res.min0    := data.min1;
			v_res.index   := '1';
			v_res.min1    := data.min0;
		end if;
		return v_res;
	end function;


	--
	-- Minimum search function reading four inputs
	-- preconditions: data.min0 <= data.min1
	--                data.min2 <= data.min3
	--
	function four_min(data : trec_min_in) return trec_min_out is
		variable v_res : trec_min_out;
		variable v_c1 : natural range 0 to 1;
		variable v_c2 : natural range 0 to 1;
		variable v_c3 : natural range 0 to 1;
	begin

		v_c1 := 0;
		v_c2 := 0;
		v_c3 := 0;

		if data.min0 <= data.min2 then
			v_c1 := 1;
		end if;
		if data.min0 <= data.min3 then
			v_c2 := 1;
		end if;
		if data.min2 <= data.min1 then
			v_c3 := 1;
		end if;

		if v_c1 = 0 then
			v_res.min0 := data.min2;
			v_res.index := '1';
		else
			v_res.min0 := data.min0;
			v_res.index := '0';
		end if;

		if v_c1 = 1 and v_c3 = 1 then
			v_res.min1 := data.min2;
		elsif v_c1 = 1 and v_c3 = 0 then
			v_res.min1 := data.min1;
		elsif v_c1 = 0 and v_c2 = 1 then
			v_res.min1 := data.min0;
		else
			v_res.min1 := data.min3;
		end if;
		return v_res;
	end function;

	--
	-- Minimum search function reading four inputs
	-- Results are sorted based on "compare",
	-- but "data" is used as return values.
	--
	-- preconditions: data.min0 <= data.min1
	--                data.min2 <= data.min3
	--
	function four_min_extra_comp(compare : trec_min_in; data : trec_min_in) return trec_min_out is
		variable v_res : trec_min_out;
		variable v_c1 : natural range 0 to 1;
		variable v_c2 : natural range 0 to 1;
		variable v_c3 : natural range 0 to 1;
	begin

		v_c1 := 0;
		v_c2 := 0;
		v_c3 := 0;

		if compare.min0 <= compare.min2 then
			v_c1 := 1;
		end if;
		if compare.min0 <= compare.min3 then
			v_c2 := 1;
		end if;
		if compare.min2 <= compare.min1 then
			v_c3 := 1;
		end if;

		if v_c1 = 0 then
			v_res.min0 := data.min2;
			v_res.index := '1';
		else
			v_res.min0 := data.min0;
			v_res.index := '0';
		end if;

		if v_c1 = 1 and v_c3 = 1 then
			v_res.min1 := data.min2;
		elsif v_c1 = 1 and v_c3 = 0 then
			v_res.min1 := data.min1;
		elsif v_c1 = 0 and v_c2 = 1 then
			v_res.min1 := data.min0;
		else
			v_res.min1 := data.min3;
		end if;
		return v_res;
	end function;


end pkg_check_node;
