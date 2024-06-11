cd [file dirname [file normalize [info script]]]
open_project ../../workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1
open_bd_design {../../workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd}
add_files -norecurse {../../boot_control/boot_control_v1_0.vhd ../../boot_control/boot_control_v1_0_S00_AXI.vhd ../../boot_control/boot_control.vhd}
update_compile_order -fileset sources_1
create_bd_cell -type module -reference boot_control_v1_0 IO/boot_control_v1_0_0
set_property location {3 954 815} [get_bd_cells IO/boot_control_v1_0_0]
create_bd_pin -dir O -from 7 -to 0 IO/led_out
create_bd_pin -dir O IO/cpu_reset
connect_bd_net [get_bd_pins IO/led_out] [get_bd_pins IO/boot_control_v1_0_0/led_out]
connect_bd_net [get_bd_pins IO/cpu_reset] [get_bd_pins IO/boot_control_v1_0_0/cpu_reset]
startgroup
set_property CONFIG.NUM_MI {5} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M04_AXI] [get_bd_intf_pins IO/boot_control_v1_0_0/s00_axi]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_control_v1_0_0/s00_axi_aresetn]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_control_v1_0_0/s00_axi_aclk]
assign_bd_address
set_property offset 0x60040000 [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_boot_control_v1_0_0_reg0}]
create_bd_port -dir O -from 7 -to 0 led_out
startgroup
connect_bd_net [get_bd_ports led_out] [get_bd_pins IO/led_out]
endgroup
delete_bd_objs [get_bd_nets reset_l]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1
endgroup
set_property location {1 140 450} [get_bd_cells util_vector_logic_1]
set_property CONFIG.C_SIZE {1} [get_bd_cells util_vector_logic_1]
connect_bd_net [get_bd_ports reset] [get_bd_pins util_vector_logic_1/Op1]
connect_bd_net [get_bd_pins IO/cpu_reset] [get_bd_pins util_vector_logic_1/Op2]
connect_bd_net [get_bd_pins util_vector_logic_1/Res] [get_bd_pins util_vector_logic_0/Op1]
add_files -fileset constrs_1 -norecurse leds.xdc
save_bd_design
validate_bd_design
launch_runs synth_1 -jobs 6
