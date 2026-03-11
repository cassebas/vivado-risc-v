# LEDs
set_property -dict {PACKAGE_PIN T28 IOSTANDARD LVCMOS33} [get_ports {led_out[0]}];
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led_out[1]}];
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVCMOS33} [get_ports {led_out[2]}];
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports {led_out[3]}];
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports {led_out[4]}];
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS33} [get_ports {led_out[5]}];
set_property -dict {PACKAGE_PIN W24 IOSTANDARD LVCMOS33} [get_ports {led_out[6]}];
set_property -dict {PACKAGE_PIN W23 IOSTANDARD LVCMOS33} [get_ports {led_out[7]}];

# Extra LEDs on a breadboard, connected to the PMOD JD connector on the
# Genesys2 board. The LEDs are mounted like this:
#           GND         GND        GND
#            |           |          |       pmod pins
#            |           |          |        654321
#          [LED3]     [LED2]     [LED1]     [......]
#            |           |          |          |||
#            ---------------------------------- ||
#                        |          |           ||
#                        ----------------------- |
#                                   -------------
#
#    VCC      GND     ========     SIGNALS    ========
#   --------------------------------------------------
#   pin06    pin05    pin04    pin03    pin02    pin01
#   pin12    pin11    pin10    pin09    pin08    pin07
#   --------------------------------------------------
#
#    Connection on pins is
#
#  Pmod pin  |     LED / signal       |     FPGA port       | FPGA Location
#  -------------------------------------------------------------------------
#    pin01   |                        |                     |      V27
#    pin02   | locked / LED1 (right)  |      bbled1         |      Y30
#    pin03   | mem_ok / LED2 (middle) |      bbled2         |      V24
#    pin04   | cpu_rst / LED3 (left)  |      bbled3         |      W22
#    pin05   |        GND             |         -           |       -
#    pin06   |        VCC             |         -           |       -
#  -------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN Y30 IOSTANDARD LVCMOS33} [get_ports bbled1];
set_property -dict {PACKAGE_PIN V24 IOSTANDARD LVCMOS33} [get_ports bbled2];
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports bbled3];
