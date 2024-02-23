set bitstream $::env(BITSTREAM)
set hw_device $::env(HW_DEVICE)

proc program_device {bitstream hw_device} {
    open_hw_manager
    connect_hw_server -allow_non_jtag
    open_hw_target
    current_hw_device [get_hw_devices ${hw_device}]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${hw_device}] 0]
    set_property PROBES.FILE {} [get_hw_devices ${hw_device}]
    set_property FULL_PROBES.FILE {} [get_hw_devices ${hw_device}]
    set_property PROGRAM.FILE ${bitstream} [get_hw_devices ${hw_device}]
    program_hw_devices [get_hw_devices ${hw_device}]
    refresh_hw_device [lindex [get_hw_devices ${hw_device}] 0]
}

set success 0

while { !$success } {
    if { [catch {program_device $bitstream $hw_device} errorstring] } {
        puts "program_device.tcl: programming device failed!"
        puts "program_device.tcl: the error was: $errorstring"
        disconnect_hw_server
    } else {
        puts "program_device.tcl: programming device was a success!"
        set success 1
    }
}
