--!
--! Copyright (C) 2010 - 2013 Creonic GmbH
--!
--! @file   pkg_support.vhd
--! @brief  Package defining useful functions
--! @author Philipp Schläfer
--! @date   2010/10/14
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg_param.all;
use work.pkg_param_derived.all;
use work.pkg_types.all;


package pkg_support is
    
    -- signal for monitoring finishing iter
    signal monitor_finish_iter: std_logic := '0';
    


	--! convert t_chv_array into std_logic_vector as input to a RAM
	function chv_array_2_std_logic_vector(input: in t_chv_array) return std_logic_vector;

	--! convert output of RAM into t_chv_array
-- 	function std_logic_vector_2_chv_array(input: in
-- 	                std_logic_vector(BW_CHV_RAM - 1 downto 0)) return t_chv_array;

	function twos_comp(data : std_logic_vector) return std_logic_vector;
	function twos_comp_neg(data : unsigned) return signed;
	function sign_magnitude(data : signed) return signed;
	function saturate(data : signed; len : natural) return signed;

	function sign_extend(data : std_logic_vector; ext : natural) return signed;
	function change_bw_sm(data : signed; ext : natural) return signed;

    -- Added by AJGP
    function ror_r(input: t_app_messages; shift: unsigned) return t_app_messages;
    
end pkg_support;


package body pkg_support is

	function chv_array_2_std_logic_vector(input: in t_chv_array) return std_logic_vector is
		variable v_out_vector : std_logic_vector(BW_CHV * NUM_VFU - 1 downto 0);
	begin

		for i in 0 to NUM_VFU - 1 loop
			v_out_vector((i + 1) * BW_CHV - 1 downto i * BW_CHV) := std_logic_vector(input(i));
		end loop;

		return v_out_vector;
	end function chv_array_2_std_logic_vector;


-- 	function std_logic_vector_2_chv_array(input: in
-- 	                std_logic_vector(BW_CHV_RAM - 1 downto 0)) return t_chv_array is
-- 		variable v_out_vector: t_chv_array;
-- 	begin
--
-- 		for i in 0 to NUM_VFU - 1 loop
-- 			v_out_vector(i) := signed(input((i + 1) * BW_CHV - 1 downto i * BW_CHV));
-- 		end loop;
--
-- 		return v_out_vector;
-- 	end function std_logic_vector_2_chv_array;


	-- convert a sign magnitude number to a two's complement representation
	function twos_comp(data : std_logic_vector) return std_logic_vector is
		variable v_data_tmp : std_logic_vector(data'high downto data'low);
	begin
		v_data_tmp := data;
		if data(data'high) = '1' then
			if unsigned(data(data'high - 1 downto 0)) = 0 then
				v_data_tmp := (others => '0');
			else
				-- turn all bits except the sign bit
				for i in data'high - 1 downto data'low loop
					v_data_tmp(i) := not(data(i));
				end loop;
				v_data_tmp := std_logic_vector(unsigned(v_data_tmp) + 1);
			end if;
			return v_data_tmp;
		else
			return data;
		end if;
	end function;

	-- convert a negative sign magnitude number to a two's complement representation
	function twos_comp_neg(data : unsigned) return signed is
		variable v_data_tmp : unsigned(data'high downto data'low);
	begin
		v_data_tmp := data;
		if unsigned(data) = 0 then
			v_data_tmp := (others => '0');
			return signed('0' & v_data_tmp);
		else
			-- turn all bits except the sign bit
			for i in data'high downto data'low loop
				v_data_tmp(i) := not(data(i));
			end loop;
			v_data_tmp := v_data_tmp + 1;
		end if;
		return signed('1' & v_data_tmp);
	end function;


	-- convert a two's complement number to a sign magnitude representation
	function sign_magnitude(data : signed) return signed is
		variable v_data_tmp : std_logic_vector(data'high downto data'low);
	begin
		v_data_tmp := std_logic_vector(data);
		if data(data'high) = '1' then
			v_data_tmp := std_logic_vector(unsigned(v_data_tmp) - 1);
			for i in data'high downto data'low loop
				v_data_tmp(i) := not(v_data_tmp(i));
			end loop;
			v_data_tmp(v_data_tmp'high) := '1';
		end if;
		return signed(v_data_tmp);
	end function;


	-- saturate the input vector and return it with full length
	function saturate(data : signed; len : natural) return signed is
	begin

		-- negative data
		if data < -(2 ** (len - 1) - 1) then
			return to_signed(-(2 ** (len - 1) - 1), len);

		-- positive data
		elsif data > (2 ** (len - 1) - 1) then
			return to_signed((2 ** (len - 1) - 1), len);
		else
			return data(len - 1 downto 0);
		end if;
	end function;


	-- sign extend two's complement represented numbers by ext digits
	function sign_extend(data : std_logic_vector; ext : natural) return signed is
		variable v_data_tmp : std_logic_vector(data'high + ext downto data'low);
	begin
		v_data_tmp(data'high downto data'low) := data;
		for i in (data'high + ext) downto (data'high + 1) loop
			v_data_tmp(i) := data(data'high);
		end loop;
		return signed(v_data_tmp);
	end function;

	-- Extend sign magnitude represented numbers by ext digits
	function change_bw_sm(data : signed; ext : natural) return signed is
		variable v_data_tmp : signed(data'high + ext downto data'low);
	begin
		v_data_tmp(data'high - 1 downto data'low) := data(data'high - 1 downto data'low);
		for i in (data'high + ext) downto (data'high + 1) loop
			v_data_tmp(i) := '0';
		end loop;
		v_data_tmp(data'high) := data(data'high);
		return v_data_tmp;
	end function;


    function ror_r(input : t_app_messages; shift: unsigned) return t_app_messages is
        variable q: t_app_messages;
        variable shift_int: integer := to_integer(shift);
    begin
        q := input(input'length - shift_int downto input'length - 1) & input(1 downto input'length - 1 - shift_int);
        return q;
    end function ror_r;


end pkg_support;
