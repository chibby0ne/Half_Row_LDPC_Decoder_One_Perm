onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /check_node_tb/rst_tb
add wave -noupdate -radix decimal /check_node_tb/clk_tb
add wave -noupdate -radix decimal -childformat {{/check_node_tb/data_in_tb(7) -radix decimal} {/check_node_tb/data_in_tb(6) -radix decimal} {/check_node_tb/data_in_tb(5) -radix decimal} {/check_node_tb/data_in_tb(4) -radix decimal} {/check_node_tb/data_in_tb(3) -radix decimal} {/check_node_tb/data_in_tb(2) -radix decimal} {/check_node_tb/data_in_tb(1) -radix decimal} {/check_node_tb/data_in_tb(0) -radix decimal}} -expand -subitemconfig {/check_node_tb/data_in_tb(7) {-radix decimal} /check_node_tb/data_in_tb(6) {-radix decimal} /check_node_tb/data_in_tb(5) {-radix decimal} /check_node_tb/data_in_tb(4) {-radix decimal} /check_node_tb/data_in_tb(3) {-radix decimal} /check_node_tb/data_in_tb(2) {-radix decimal} /check_node_tb/data_in_tb(1) {-radix decimal} /check_node_tb/data_in_tb(0) {-radix decimal}} /check_node_tb/data_in_tb
add wave -noupdate -radix decimal /check_node_tb/split_tb
add wave -noupdate -radix decimal -childformat {{/check_node_tb/data_out_tb(7) -radix decimal} {/check_node_tb/data_out_tb(6) -radix decimal} {/check_node_tb/data_out_tb(5) -radix decimal} {/check_node_tb/data_out_tb(4) -radix decimal} {/check_node_tb/data_out_tb(3) -radix decimal} {/check_node_tb/data_out_tb(2) -radix decimal} {/check_node_tb/data_out_tb(1) -radix decimal} {/check_node_tb/data_out_tb(0) -radix decimal}} -expand -subitemconfig {/check_node_tb/data_out_tb(7) {-radix decimal} /check_node_tb/data_out_tb(6) {-radix decimal} /check_node_tb/data_out_tb(5) {-radix decimal} /check_node_tb/data_out_tb(4) {-radix decimal} /check_node_tb/data_out_tb(3) {-radix decimal} /check_node_tb/data_out_tb(2) {-radix decimal} /check_node_tb/data_out_tb(1) {-radix decimal} /check_node_tb/data_out_tb(0) {-radix decimal}} /check_node_tb/data_out_tb
add wave -noupdate -radix decimal /check_node_tb/parity_out_tb
add wave -noupdate -radix decimal /check_node_tb/first
add wave -noupdate /check_node_tb/dut/data_in_sign
add wave -noupdate /check_node_tb/dut/data_in_mag
add wave -noupdate /check_node_tb/dut/sort_in
add wave -noupdate /check_node_tb/dut/sort_out
add wave -noupdate /check_node_tb/dut/four_min_s1_in
add wave -noupdate /check_node_tb/dut/four_min_s2_in
add wave -noupdate /check_node_tb/dut/four_min_s3_in
add wave -noupdate /check_node_tb/dut/four_min_s1_out
add wave -noupdate /check_node_tb/dut/four_min_s2_out
add wave -noupdate /check_node_tb/dut/four_min_s3_out
add wave -noupdate /check_node_tb/dut/data_out_neg_tc
add wave -noupdate /check_node_tb/dut/data_out_pos_tc
add wave -noupdate /check_node_tb/dut/data_in_reg
add wave -noupdate /check_node_tb/dut/data_out_reg
add wave -noupdate /check_node_tb/dut/four_min_s2_out_first_half
add wave -noupdate /check_node_tb/dut/four_min_s2_out_first_half_reg
add wave -noupdate /check_node_tb/dut/index_s2_first_half
add wave -noupdate /check_node_tb/dut/index_s2_first_half_reg
add wave -noupdate /check_node_tb/dut/parity_s3_in_first_half
add wave -noupdate /check_node_tb/dut/parity_s3_in_first_half_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {811 ns}
