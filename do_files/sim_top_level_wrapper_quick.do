vsim work.tb_top_level_wrapper
add wave -unsigned sim:/clk_tb
add wave -decimal sim:/input_tb
add wave -unsigned sim:/dut/top_level_ins/iter
add wave -unsigned sim:/valid_output_tb
add wave -unsigned sim:/new_codeword_tb
add wave -unsigned sim:/output_tb

run -all
