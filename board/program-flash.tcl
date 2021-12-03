open_hw_manager
connect_hw_server -url "$::env(HW_SERVER_ADDR)"
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [current_hw_device]
create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts "$::env(CFG_PART)"] 0]
current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]
set_property PROGRAM.FILES [list "$::env(mcs_file)"] [current_hw_cfgmem]
set_property PROGRAM.PRM_FILE "$::env(prm_file)" [current_hw_cfgmem]
set_property PROGRAM.ERASE 1 [current_hw_cfgmem]
set_property PROGRAM.BLANK_CHECK 1 [current_hw_cfgmem]
set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]
set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]
set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]
set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]
create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]
program_hw_devices [current_hw_device]
refresh_hw_device [current_hw_device]
program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]