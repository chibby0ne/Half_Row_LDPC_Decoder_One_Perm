--!
--! Copyright (C) 2010 creonic UG (haftungsbeschränkt)
--!
--! @file
--! @brief  Support package with useful functions
--! @author Matthias Alles
--! @date   2010/07/14
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg_support_global is

	--!
	--! Return the log_2 of an natural value, i.e. the number of bits required
	--! to represent this unsigned value.
	--!
	function no_bits_natural(value_in : natural) return natural;

	--!
	--! Return maximum of two input values
	--!
	function max(value_in_a, value_in_b : natural) return natural;

	--! saturation of a signed value to BW bits
	function saturate(value: in signed; BW : in natural) return signed;


	--! ceil function for division of quit / divisor
	function ceil(quot : in natural; divisor : in natural) return natural;


	--!
	--! Procedure to simplify scrambling. Inputs are:
	--!  - sreg_polynom: shunts of the shift register, has to be one bit wider than sreg.
	--!  - sreg        : current register content, returns updated register content.
	--!  - swap_flag   : indicate, whether the current bit needs swapping.
	--!
	procedure scramble(sreg_polynom : in    std_logic_vector;
	                   v_sreg       : inout std_logic_vector;
	                   v_swap_flag  : out   std_logic);

end pkg_support_global;


package body pkg_support_global is


	function no_bits_natural(value_in: natural) return natural is
		variable v_n_bit : unsigned(31 downto 0);
	begin
		if value_in = 0 then
			return 0;
		end if;
		v_n_bit := to_unsigned(value_in, 32);
		for i in 31 downto 0 loop
			if v_n_bit(i) = '1' then
				return i + 1;
			end if;
		end loop;
		return 1;
	end no_bits_natural;


	function max(value_in_a, value_in_b : natural) return natural is
	begin
		if value_in_a > value_in_b then
			return value_in_a;
		else
			return value_in_b;
		end if;
	end function;


	-- saturation of a signed value to BW bits
	function saturate(value: in signed; BW : in natural) return signed is
	begin
		if value > 2 ** (BW - 1) - 1 then
			return to_signed(2 ** (BW - 1) - 1, BW);
		elsif value < -2 ** (BW - 1) + 1 then
			-- +1 because of signed magnitude
			return to_signed(-2 ** (BW - 1) + 1, BW);
		else
			return value(BW - 1 downto 0);
		end if;
	end function saturate;


	function ceil(quot : in natural; divisor : in natural) return natural is
	begin
		if (quot + divisor - 1) / divisor > quot / divisor then
			return quot / divisor + 1;
		else
			return quot / divisor;
		end if;
	end function;

   
	procedure scramble(sreg_polynom : in    std_logic_vector;
	                   v_sreg       : inout std_logic_vector;
	                   v_swap_flag  : out   std_logic) is
		variable v_bit_swap : std_logic;
	begin
		v_bit_swap := '0';
		for i in 0 to v_sreg'length - 1 loop
			if v_sreg(i) = '1' and sreg_polynom(i + 1) = '1' then
				v_bit_swap := not v_bit_swap;
			end if;
		end loop;
		v_sreg      := v_sreg(v_sreg'length - 2 downto 0) & v_bit_swap;
		v_swap_flag := v_bit_swap;
	end procedure scramble;

    
end pkg_support_global;
