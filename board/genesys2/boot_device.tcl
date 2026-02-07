set core_config $::env(CONFIG)
puts "boot_device.tcl: using core configuration ${core_config}"

open_project workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1

set project_dir [get_property DIRECTORY [current_project]]
puts "boot_device.tcl: project directory is ${project_dir}"

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0
set_property -dict [list \
  CONFIG.Byte_Size {8} \
  CONFIG.Coe_File ${project_dir}/../../../boot_device/bsort.coe \
  CONFIG.Enable_A {Always_Enabled} \
  CONFIG.Fill_Remaining_Memory_Locations {true} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Write_Depth_A {16384} \
  CONFIG.Write_Width_A {32} \
] [get_ips blk_mem_gen_0]
generate_target {instantiation_template} [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]
generate_target all [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]
catch { config_ip_cache -export [get_ips -all blk_mem_gen_0] }

export_ip_user_files -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]

launch_runs blk_mem_gen_0_synth_1 -jobs 6

export_simulation -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -directory workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.ip_user_files/sim_scripts -ip_user_files_dir workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.ip_user_files -ipstatic_source_dir workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.ip_user_files/ipstatic -lib_map_path [list {modelsim=workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.cache/compile_simlib/modelsim} {questa=workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.cache/compile_simlib/questa} {xcelium=workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.cache/compile_simlib/xcelium} {vcs=workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.cache/compile_simlib/vcs} {riviera=workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

add_files -norecurse {boot_device/boot_device.vhd boot_device/boot_device_axislave.vhd boot_device/boot_device_bootcode.vhd boot_device/blk_mem_gen_0.vhd}
update_compile_order -fileset sources_1

open_bd_design ${project_dir}/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd
create_bd_cell -type module -reference boot_device IO/boot_device_0
startgroup
set_property CONFIG.NUM_MI {6} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M05_AXI] -boundary_type upper [get_bd_intf_pins IO/boot_device_0/S00_AXI]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_device_0/S00_AXI_aclk]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_device_0/S00_AXI_aresetn]
assign_bd_address [get_bd_addr_segs {IO/boot_device_0/S00_AXI/reg0}]
set_property offset 0x60050000 [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_boot_device_0_reg0}]
set_property range 64K [get_bd_addr_segs {RocketChip/IO_AXI4/SEG_boot_device_0_reg0}]
update_compile_order -fileset sources_1
validate_bd_design
save_bd_design
reset_run riscv_axi_smc_1_0_synth_1
reset_run riscv_io_axi_m_0_synth_1
reset_run riscv_io_axi_s_0_synth_1
reset_run synth_1
launch_runs synth_1 -jobs 6
