cd [file dirname [file normalize [info script]]]
open_project ../../workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1
open_bd_design {../../workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd}
add_files -norecurse {../../reset_control/reset_control_v1_0.vhd ../../reset_control/reset_control_v1_0_S00_AXI.vhd ../../reset_control/reset_control.vhd ../../reset_control/debug_reset_control.vhd}
add_files -fileset constrs_1 -norecurse ../../board/genesys2/debug_signals.xdc
update_compile_order -fileset sources_1

create_bd_cell -type module -reference reset_control_v1_0 IO/reset_control_v1_0_0
create_bd_pin -dir O IO/cpu_reset_n
connect_bd_net [get_bd_pins IO/cpu_reset_n] [get_bd_pins IO/reset_control_v1_0_0/cpu_reset_n]

create_bd_cell -type module -reference debug_reset_control IO/debug_reset_control
create_bd_pin -dir O IO/dbg_cpu_reset_n
connect_bd_net [get_bd_pins IO/dbg_cpu_reset_n] [get_bd_pins IO/debug_reset_control/dbg_cpu_reset_n]

create_bd_pin -dir O IO/dbg_logic_set
connect_bd_net [get_bd_pins IO/dbg_logic_set] [get_bd_pins IO/debug_reset_control/dbg_logic_set]

create_bd_pin -dir O IO/dbg_logic_reset
connect_bd_net [get_bd_pins IO/dbg_logic_reset] [get_bd_pins IO/debug_reset_control/dbg_logic_reset]

startgroup
set_property CONFIG.NUM_MI {5} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M04_AXI] [get_bd_intf_pins IO/reset_control_v1_0_0/s00_axi]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/reset_control_v1_0_0/s00_axi_aresetn]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/reset_control_v1_0_0/s00_axi_aclk]

connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/debug_reset_control/clk]
connect_bd_net [get_bd_pins IO/reset_control_v1_0_0/cpu_reset_n] [get_bd_pins IO/debug_reset_control/cpu_reset_n]
connect_bd_net [get_bd_pins IO/reset_control_v1_0_0/logic_set] [get_bd_pins IO/debug_reset_control/logic_set]
connect_bd_net [get_bd_pins IO/reset_control_v1_0_0/logic_reset] [get_bd_pins IO/debug_reset_control/logic_reset]

assign_bd_address
set_property offset 0x60040000 [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_reset_control_v1_0_0_reg0}]
delete_bd_objs [get_bd_nets reset_l]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1
endgroup
set_property location {1 140 450} [get_bd_cells util_vector_logic_1]
set_property CONFIG.C_SIZE {1} [get_bd_cells util_vector_logic_1]
connect_bd_net [get_bd_ports reset] [get_bd_pins util_vector_logic_1/Op1]
connect_bd_net [get_bd_pins IO/cpu_reset_n] [get_bd_pins util_vector_logic_1/Op2]
connect_bd_net [get_bd_pins util_vector_logic_1/Res] [get_bd_pins util_vector_logic_0/Op1]
# add_files -fileset constrs_1 -norecurse leds.xdc
save_bd_design
validate_bd_design
launch_runs synth_1 -jobs 6
