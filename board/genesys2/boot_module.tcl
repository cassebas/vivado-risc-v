open_project workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1
add_files -norecurse {boot_module/boot_module_v1_0_S00_AXI.vhd boot_module/boot_module_v1_0.vhd}
update_compile_order -fileset sources_1
create_bd_design "boot_module"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
set_property -dict [list \
                        CONFIG.Byte_Size {8} \
                        CONFIG.Coe_File {../../../../../../../../../boot_module/bram_initialization.coe} \
                        CONFIG.Enable_A {Always_Enabled} \
                        CONFIG.Fill_Remaining_Memory_Locations {true} \
                        CONFIG.Load_Init_File {true} \
                        CONFIG.Operating_Mode_A {READ_FIRST} \
                        CONFIG.Use_Byte_Write_Enable {true} \
                        CONFIG.Write_Depth_A {16384} \
                        CONFIG.Write_Width_A {32} \
                        CONFIG.use_bram_block {Stand_Alone} \
                       ] [get_bd_cells blk_mem_gen_0]
create_bd_cell -type module -reference boot_module_v1_0 boot_module_v1_0_0
connect_bd_net [get_bd_pins boot_module_v1_0_0/bram_clk_o] [get_bd_pins blk_mem_gen_0/clka]
connect_bd_net [get_bd_pins boot_module_v1_0_0/bram_addr_o] [get_bd_pins blk_mem_gen_0/addra]
connect_bd_net [get_bd_pins boot_module_v1_0_0/bram_data_o] [get_bd_pins blk_mem_gen_0/dina]
connect_bd_net [get_bd_pins blk_mem_gen_0/douta] [get_bd_pins boot_module_v1_0_0/bram_data_i]
connect_bd_net [get_bd_pins boot_module_v1_0_0/bram_wea_o] [get_bd_pins blk_mem_gen_0/wea]
startgroup
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s00_axi
set_property -dict [list CONFIG.PROTOCOL [get_property CONFIG.PROTOCOL [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.ADDR_WIDTH [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.HAS_BURST [get_property CONFIG.HAS_BURST [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.HAS_LOCK [get_property CONFIG.HAS_LOCK [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.HAS_CACHE [get_property CONFIG.HAS_CACHE [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.HAS_QOS [get_property CONFIG.HAS_QOS [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.HAS_REGION [get_property CONFIG.HAS_REGION [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.SUPPORTS_NARROW_BURST [get_property CONFIG.SUPPORTS_NARROW_BURST [get_bd_intf_pins boot_module_v1_0_0/s00_axi]] CONFIG.MAX_BURST_LENGTH [get_property CONFIG.MAX_BURST_LENGTH [get_bd_intf_pins boot_module_v1_0_0/s00_axi]]] [get_bd_intf_ports s00_axi]
connect_bd_intf_net [get_bd_intf_pins boot_module_v1_0_0/s00_axi] [get_bd_intf_ports s00_axi]
endgroup
startgroup
create_bd_port -dir I -type clk -freq_hz 100000000 s00_axi_aclk
connect_bd_net [get_bd_pins /boot_module_v1_0_0/s00_axi_aclk] [get_bd_ports s00_axi_aclk]
endgroup
startgroup
create_bd_port -dir I -type rst s00_axi_aresetn
connect_bd_net [get_bd_pins /boot_module_v1_0_0/s00_axi_aresetn] [get_bd_ports s00_axi_aresetn]
endgroup
regenerate_bd_layout
validate_bd_design
save_bd_design

open_bd_design {workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd}
create_bd_cell -type container -reference boot_module IO/boot_module_0
startgroup
set_property CONFIG.NUM_MI {6} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M05_AXI] -boundary_type upper [get_bd_intf_pins IO/boot_module_0/s00_axi]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_module_0/s00_axi_aclk]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_module_0/s00_axi_aresetn]
assign_bd_address -target_address_space /RocketChip/IO_AXI4 [get_bd_addr_segs IO/boot_module_0/boot_module_v1_0_0/s00_axi/reg0] -force
set_property offset 0x60050000 [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_boot_module_v1_0_0_reg0}]
set_property range 64K [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_boot_module_v1_0_0_reg0}]
validate_bd_design
save_bd_design
reset_run riscv_axi_smc_1_0_synth_1
reset_run riscv_io_axi_m_0_synth_1
reset_run riscv_io_axi_s_0_synth_1
reset_run synth_1
launch_runs synth_1 -jobs 6
