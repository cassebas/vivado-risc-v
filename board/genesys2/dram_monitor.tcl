open_project workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.xpr
update_compile_order -fileset sources_1
open_bd_design {/home/caspar/local/git/vivado-risc-v/workspace/rocket32s1/vivado-genesys2-riscv/genesys2-riscv.srcs/sources_1/bd/riscv/riscv.bd}
add_files -norecurse /home/caspar/local/git/vivado-risc-v/dram_monitor/axi4_passthrough.vhdl
update_compile_order -fileset sources_1
create_bd_cell -type module -reference axi4_passthrough DDR/axi4_passthrough_0
delete_bd_objs [get_bd_intf_nets DDR/MEM_AXI4]
connect_bd_net [get_bd_pins DDR/axi_clock] [get_bd_pins DDR/axi4_passthrough_0/aclk]
connect_bd_intf_net [get_bd_intf_pins DDR/S00_AXI] [get_bd_intf_pins DDR/axi4_passthrough_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins DDR/axi4_passthrough_0/M00_AXI] [get_bd_intf_pins DDR/axi_smc_1/S00_AXI]
connect_bd_net [get_bd_pins DDR/axi_reset] [get_bd_pins DDR/axi4_passthrough_0/aresetn]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 DDR/fifo_generator_0
endgroup
set_property -dict [list \
  CONFIG.Fifo_Implementation {Common_Clock_Builtin_FIFO} \
  CONFIG.Input_Data_Width {32} \
] [get_bd_cells DDR/fifo_generator_0]
connect_bd_net [get_bd_pins DDR/fifo_generator_0/full] [get_bd_pins DDR/axi4_passthrough_0/fifo_full_i]
connect_bd_net [get_bd_pins DDR/axi4_passthrough_0/fifo_wren_o] [get_bd_pins DDR/fifo_generator_0/wr_en]
connect_bd_net [get_bd_pins DDR/axi4_passthrough_0/fifo_din_o] [get_bd_pins DDR/fifo_generator_0/din]
connect_bd_net [get_bd_pins DDR/axi_clock] [get_bd_pins DDR/fifo_generator_0/clk]
connect_bd_net [get_bd_pins DDR/sys_reset] [get_bd_pins DDR/fifo_generator_0/rst]
regenerate_bd_layout -hierarchy [get_bd_cells DDR]
set_property BRIDGES M00_AXI [get_bd_intf_pins /DDR/axi4_passthrough_0/S00_AXI]
set_property CONFIG.CLK_DOMAIN riscv_clk_wiz_0_0_clk_out1 [get_bd_intf_pins /DDR/axi4_passthrough_0/S00_AXI]
set_property CONFIG.CLK_DOMAIN riscv_clk_wiz_0_0_clk_out1 [get_bd_intf_pins /DDR/axi4_passthrough_0/M00_AXI]
exclude_bd_addr_seg [get_bd_addr_segs DDR/axi4_passthrough_0/S00_AXI/reg0] -target_address_space [get_bd_addr_spaces RocketChip/MEM_AXI4]
validate_bd_design
save_bd_design
reset_run synth_1
launch_runs synth_1 -jobs 6
