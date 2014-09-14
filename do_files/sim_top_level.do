vsim work.tb_top_level
add wave -unsigned sim:/clk_tb
add wave -decimal sim:/input_tb
add wave -decimal sim:/dut/input_newcode
add wave -unsigned sim:/dut/sel_mux_input_halves
add wave -unsigned sim:/dut/shifting_info_out
add wave -unsigned sim:/dut/input_or_cnb
add wave -unsigned sim:/dut/sel_mux_input_app_second
add wave -decimal sim:/dut/app_in 
add wave -unsigned sim:/dut/sel_mux_output_app
add wave -unsigned sim:/dut/sel_mux_input_app

add wave -decimal sim:/dut/mux_output_app_out
add wave -decimal sim:/dut/gen_app_ram(0)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(1)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(2)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(3)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(4)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(5)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(6)/app_ram_ins/myram
add wave -decimal sim:/dut/gen_app_ram(7)/app_ram_ins/myram

add wave -decimal sim:/dut/app_out 
add wave -decimal sim:/dut/perm_input
add wave -unsigned sim:/dut/shift
add wave -decimal sim:/dut/perm_output
add wave -decimal sim:/dut/cnb_input

add wave -decimal sim:/dut/cnb_output



add wave -decimal sim:/dut/cnb_output_in_app

add wave -unsigned sim:/dut/app_rd_addr
add wave -unsigned sim:/dut/app_wr_addr
add wave -unsigned sim:/dut/msg_rd_addr
add wave -unsigned sim:/dut/msg_wr_addr
add wave -unsigned sim:/dut/sel_mux_input_app_second


add wave -unsigned sim:/dut/gen_cnbs(0)/cnbs_ins/addr_msg_ram_read_reg
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/app_in_reg
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/zetas
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/extrinsic_info_read
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/check_node_out
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/extrinsic_info_write
add wave -signed sim:/dut/gen_cnbs(0)/cnbs_ins/msg_ram_ins/myram

add wave -unsigned sim:/dut/controller_ins/pr_state
add wave -unsigned sim:/dut/ena_vc
add wave -unsigned sim:/dut/ena_rp
add wave -unsigned sim:/dut/ena_ct
add wave -unsigned sim:/dut/ena_cf
add wave -unsigned sim:/dut/iter

add wave -unsigned sim:/valid_output_tb
add wave -unsigned sim:/new_codeword_tb
add wave -unsigned sim:/dut/controller_ins/ok_checks_sig
add wave -unsigned sim:/dut/controller_ins/pchecks_sig
add wave -unsigned sim:/dut/controller_ins/cng_counter_sig
add wave -unsigned sim:/dut/parity_out
add wave -unsigned sim:/dut/parity_out_reg

add wave -unsigned sim:/dut/finish_iter
add wave -unsigned sim:/dut/output_in
add wave -unsigned sim:/dut/output_module_ins/input_reg_sig
add wave -unsigned sim:/output_tb

run -all
