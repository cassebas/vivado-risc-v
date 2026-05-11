set core_config $::env(CONFIG)
puts "boot_device.tcl: using core configuration ${core_config}"

open_project workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1

set project_dir [get_property DIRECTORY [current_project]]
puts "boot_device.tcl: project directory is ${project_dir}"

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_app_0
set_property -dict [list \
  CONFIG.Enable_A {Always_Enabled} \
  CONFIG.Byte_Size {8} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Write_Depth_A {16384} \
  CONFIG.Write_Width_A {32} \
  CONFIG.use_bram_block {Stand_Alone} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Coe_File ${project_dir}/../../../boot_device/bootstrap.coe \
  CONFIG.Fill_Remaining_Memory_Locations {true} \
] [get_ips blk_mem_app_0]
generate_target {instantiation_template} [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_0/blk_mem_app_0.xci]
generate_target all [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_0/blk_mem_app_0.xci]
catch { config_ip_cache -export [get_ips -all blk_mem_app_0] }

export_ip_user_files -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_0/blk_mem_app_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_0/blk_mem_app_0.xci]

launch_runs blk_mem_app_0_synth_1 -jobs 6


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_app_1
set_property -dict [list \
  CONFIG.Enable_A {Always_Enabled} \
  CONFIG.Byte_Size {8} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Write_Depth_A {65536} \
  CONFIG.Write_Width_A {32} \
  CONFIG.use_bram_block {Stand_Alone} \
] [get_ips blk_mem_app_1]
generate_target {instantiation_template} [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_1/blk_mem_app_1.xci]
generate_target all [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_1/blk_mem_app_1.xci]
catch { config_ip_cache -export [get_ips -all blk_mem_app_1] }

export_ip_user_files -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_1/blk_mem_app_1.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_app_1/blk_mem_app_1.xci]

launch_runs blk_mem_app_1_synth_1 -jobs 6


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_data_0
set_property -dict [list \
  CONFIG.Enable_A {Always_Enabled} \
  CONFIG.Byte_Size {8} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Write_Depth_A {4096} \
  CONFIG.Write_Width_A {32} \
  CONFIG.use_bram_block {Stand_Alone} \
] [get_ips blk_mem_data_0]

generate_target {instantiation_template} [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_0/blk_mem_data_0.xci]

generate_target all [get_files  workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_0/blk_mem_data_0.xci]
catch { config_ip_cache -export [get_ips -all blk_mem_data_0] }
export_ip_user_files -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_0/blk_mem_data_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_0/blk_mem_data_0.xci]

launch_runs blk_mem_data_0_synth_1 -jobs 6


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_data_1
set_property -dict [list \
  CONFIG.Enable_A {Always_Enabled} \
  CONFIG.Byte_Size {8} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Write_Depth_A {4096} \
  CONFIG.Write_Width_A {32} \
  CONFIG.use_bram_block {Stand_Alone} \
] [get_ips blk_mem_data_1]

generate_target {instantiation_template} [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_1/blk_mem_data_1.xci]

generate_target all [get_files  workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_1/blk_mem_data_1.xci]
catch { config_ip_cache -export [get_ips -all blk_mem_data_1] }
export_ip_user_files -of_objects [get_files workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_1/blk_mem_data_1.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] workspace/${core_config}/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/ip/blk_mem_data_1/blk_mem_data_1.xci]

launch_runs blk_mem_data_1_synth_1 -jobs 6


add_files -norecurse { \
                           boot_device/boot_device.vhd \
                           boot_device/boot_device_axislave.vhd \
                           boot_device/boot_device_addrtranslator.vhd \
                           boot_device/boot_device_datafiller.vhd \
                           boot_device/boot_device_datarcv.vhd \
                           boot_device/blk_mem_app_0.vhd \
                           boot_device/blk_mem_app_1.vhd \
                           boot_device/blk_mem_data_0.vhd \
                           boot_device/blk_mem_data_1.vhd }

add_files -fileset constrs_1 -norecurse board/genesys2/uart_extra.xdc
add_files -fileset constrs_1 -norecurse board/genesys2/leds.xdc

update_compile_order -fileset sources_1


open_bd_design ${project_dir}/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd
create_bd_cell -type module -reference boot_device IO/boot_device_0
startgroup
set_property CONFIG.NUM_MI {7} [get_bd_cells IO/io_axi_s]
endgroup
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M05_AXI] -boundary_type upper [get_bd_intf_pins IO/boot_device_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins IO/io_axi_s/M06_AXI] -boundary_type upper [get_bd_intf_pins IO/boot_device_0/S01_AXI]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_device_0/S00_AXI_aclk]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_device_0/S00_AXI_aresetn]
connect_bd_net [get_bd_pins IO/axi_clock] [get_bd_pins IO/boot_device_0/S01_AXI_aclk]
connect_bd_net [get_bd_pins IO/axi_reset] [get_bd_pins IO/boot_device_0/S01_AXI_aresetn]
connect_bd_net [get_bd_pins IO/reset_control_v1_0_0/cpu_reset_n] [get_bd_pins IO/boot_device_0/cpu_reset_n]

startgroup
create_bd_pin -dir O IO/usb_uart_extra_rtsn
connect_bd_net [get_bd_pins IO/usb_uart_extra_rtsn] [get_bd_pins IO/boot_device_0/rtsn_o]
endgroup
startgroup
create_bd_pin -dir O IO/usb_uart_extra_txd
connect_bd_net [get_bd_pins IO/usb_uart_extra_txd] [get_bd_pins IO/boot_device_0/tx_o]
endgroup
startgroup
create_bd_pin -dir I IO/usb_uart_extra_rxd
connect_bd_net [get_bd_pins IO/usb_uart_extra_rxd] [get_bd_pins IO/boot_device_0/rx_i]
endgroup
startgroup
create_bd_pin -dir I IO/usb_uart_extra_ctsn
connect_bd_net [get_bd_pins IO/usb_uart_extra_ctsn] [get_bd_pins IO/boot_device_0/ctsn_i]
endgroup
startgroup
connect_bd_net [get_bd_pins IO/boot_device_0/interrupt] [get_bd_pins IO/xlconcat_0/In3]
endgroup
startgroup
create_bd_pin -dir O -from 7 -to 0 IO/led_out
endgroup
connect_bd_net [get_bd_pins IO/boot_device_0/led_out] [get_bd_pins IO/led_out]

startgroup
create_bd_port -dir O usb_uart_extra_rtsn
connect_bd_net [get_bd_ports usb_uart_extra_rtsn] [get_bd_pins IO/usb_uart_extra_rtsn]
endgroup
startgroup
create_bd_port -dir O usb_uart_extra_txd
connect_bd_net [get_bd_pins /IO/usb_uart_extra_txd] [get_bd_ports usb_uart_extra_txd]
endgroup
startgroup
create_bd_port -dir I usb_uart_extra_rxd
connect_bd_net [get_bd_pins /IO/usb_uart_extra_rxd] [get_bd_ports usb_uart_extra_rxd]
endgroup
startgroup
create_bd_port -dir I usb_uart_extra_ctsn
connect_bd_net [get_bd_ports usb_uart_extra_ctsn] [get_bd_pins IO/usb_uart_extra_ctsn]
endgroup
create_bd_port -dir O -from 7 -to 0 led_out
connect_bd_net [get_bd_ports led_out] [get_bd_pins IO/led_out]

assign_bd_address \
    -offset 0x60050000 \
    -range  0x00010000 \
    -target_address_space \
        [get_bd_addr_spaces RocketChip/IO_AXI4] \
        [get_bd_addr_segs IO/boot_device_0/S00_AXI/reg0] -force

assign_bd_address \
    -offset 0x60080000 \
    -range  0x00040000 \
    -target_address_space \
        [get_bd_addr_spaces RocketChip/IO_AXI4] \
        [get_bd_addr_segs IO/boot_device_0/S01_AXI/reg0] -force

update_compile_order -fileset sources_1

create_bd_port -dir O bbled1
create_bd_port -dir O bbled2
connect_bd_net [get_bd_ports bbled2] [get_bd_pins DDR/mem_ok]
connect_bd_net [get_bd_ports bbled1] [get_bd_pins clk_wiz_0/locked]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2
endgroup
set_property -dict [list \
  CONFIG.C_OPERATION {not} \
  CONFIG.C_SIZE {1} \
] [get_bd_cells util_vector_logic_2]
create_bd_port -dir O bbled3
connect_bd_net [get_bd_pins IO/cpu_reset_n] [get_bd_pins util_vector_logic_2/Op1]
connect_bd_net [get_bd_pins util_vector_logic_2/Res] [get_bd_ports bbled3]

validate_bd_design
save_bd_design
reset_run riscv_axi_smc_1_0_synth_1
reset_run riscv_io_axi_m_0_synth_1
reset_run riscv_io_axi_s_0_synth_1
reset_run synth_1
launch_runs synth_1 -jobs 6
