open_project workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1
create_bd_design "boot_memory"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
set_property CONFIG.use_bram_block {BRAM_Controller} [get_bd_cells blk_mem_gen_0]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
set_property CONFIG.SINGLE_PORT_BRAM {1} [get_bd_cells axi_bram_ctrl_0]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
set_property -dict [list CONFIG.ADDR_WIDTH [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]] CONFIG.HAS_QOS [get_property CONFIG.HAS_QOS [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]] CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]] CONFIG.NUM_READ_OUTSTANDING [get_property CONFIG.NUM_READ_OUTSTANDING [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]] CONFIG.NUM_WRITE_OUTSTANDING [get_property CONFIG.NUM_WRITE_OUTSTANDING [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]]] [get_bd_intf_ports S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/S_AXI] [get_bd_intf_ports S_AXI]
endgroup
startgroup
create_bd_port -dir I -type clk -freq_hz 100000000 s_axi_aclk
connect_bd_net [get_bd_pins /axi_bram_ctrl_0/s_axi_aclk] [get_bd_ports s_axi_aclk]
endgroup
startgroup
create_bd_port -dir I -type rst s_axi_aresetn
connect_bd_net [get_bd_pins /axi_bram_ctrl_0/s_axi_aresetn] [get_bd_ports s_axi_aresetn]
endgroup
regenerate_bd_layout
validate_bd_design
save_bd_design
open_bd_design {/home/caspar/local/git/vivado-risc-v/workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd}
create_bd_cell -type container -reference boot_memory IO/boot_memory_0
startgroup
set_property CONFIG.NUM_MI {6} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M05_AXI] -boundary_type upper [get_bd_intf_pins IO/boot_memory_0/S_AXI]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_memory_0/s_axi_aclk]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_memory_0/s_axi_aresetn]
assign_bd_address -target_address_space /RocketChip/IO_AXI4 [get_bd_addr_segs IO/boot_memory_0/axi_bram_ctrl_0/S_AXI/Mem0] -force
set_property range 64K [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_axi_bram_ctrl_0_Mem0}]
set_property offset 0x60050000 [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_axi_bram_ctrl_0_Mem0}]
reset_run riscv_axi_smc_1_0_synth_1
reset_run riscv_io_axi_m_0_synth_1
reset_run riscv_io_axi_s_0_synth_1
validate_bd_design
save_bd_design
reset_run synth_1
launch_runs synth_1 -jobs 6
