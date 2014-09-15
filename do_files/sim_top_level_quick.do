vsim work.tb_top_level
add wave -unsigned sim:/clk_tb
add wave -decimal sim:/input_tb
add wave -unsigned sim:/dut/iter
add wave -unsigned sim:/dut/controller_ins/pr_state
add wave -unsigned sim:/valid_output_tb
add wave -unsigned sim:/new_codeword_tb
add wave -unsigned sim:/output_tb

run -all
