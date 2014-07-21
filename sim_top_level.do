vsim work.top_level_tb
add wave -unsigned sim:/clk_tb
add wave -decimal sim:/input_tb
add wave -decimal sim:/dut/mux_app_input_in_newcode
add wave -unsigned sim:/dut/mux_input_halves
add wave -decimal sim:/dut/mux_app_input_in_cnb
add wave -unsigned sim:/dut/mux_input_app
add wave -decimal sim:/dut/mux_output_in_app 
add wave -decimal sim:/dut/app_in 
add wave -decimal sim:/dut/app_out 
add wave -decimal sim:/dut/mux_app_output_in_mux
add wave -decimal sim:/dut/mux_app_output_in_dummy
add wave -unsigned sim:/dut/mux_output_app
add wave -decimal sim:/dut/mux_app_output_out
add wave -decimal sim:/dut/gen_app_ram(7)/app_ram_ins/myram
add wave -decimal sim:/dut/perm_input
add wave -unsigned sim:/dut/shift
add wave -decimal sim:/dut/perm_output
add wave -decimal sim:/dut/cnb_input
add wave -decimal sim:/dut/cnb_output

add wave -unsigned sim:/dut/controller_ins/pr_state
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/app_in_reg
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/zetas
add wave -unsigned sim:/dut/gen_cnbs(41)/cnbs_ins/addr_msg_ram_read_reg
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/extrinsic_info_read
add wave -unsigned sim:/dut/gen_cnbs(41)/cnbs_ins/addr_msg_ram_write
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/extrinsic_info_write
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/check_node_in_reg_out
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/check_node_out
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/zetas_fifo_out
add wave -decimal sim:/dut/gen_cnbs(41)/cnbs_ins/app_out
add wave -unsigned sim:/dut/gen_cnbs(41)/cnbs_ins/check_node_ins/four_min_s3_out_out_mux
add wave -unsigned sim:/dut/gen_cnbs(41)/cnbs_ins/check_node_ins/data_in_mag_i
add wave -unsigned sim:/dut/gen_cnbs(41)/cnbs_ins/check_node_ins/count


add wave -decimal sim:/dut/cnb_output
add wave -decimal sim:/dut/mux_app_input_in_cnb

add wave -unsigned sim:/dut/ena_vc
add wave -unsigned sim:/dut/ena_rp
add wave -unsigned sim:/dut/ena_ct
add wave -unsigned sim:/dut/ena_cf

add wave -unsigned sim:/dut/app_rd_addr
add wave -unsigned sim:/dut/app_wr_addr
add wave -unsigned sim:/dut/msg_rd_addr
add wave -unsigned sim:/dut/msg_wr_addr

add wave -unsigned sim:/dut/iter

add wave -unsigned sim:/valid_output_tb
add wave -unsigned sim:/dut/hard_bits_cnb
add wave -unsigned sim:/output_tb

run -all
