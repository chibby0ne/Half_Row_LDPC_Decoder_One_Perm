vsim work.check_node_block_tb
add wave sim:/*
add wave -decimal sim:/dut/app_in_reg
add wave -decimal sim:/dut/zetas
add wave sim:/dut/check_node_in_reg_out
add wave -decimal sim:/dut/check_node_out
add wave -decimal sim:/dut/extrinsic_info_read
run -all 
