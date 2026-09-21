# Debug signals connected to PMOD JD connector of Genesys2 board
#
#    VCC      GND     ========     SIGNALS    ========
#   --------------------------------------------------
#   pin06    pin05    pin04    pin03    pin02    pin01
#   pin12    pin11    pin10    pin09    pin08    pin07
#   --------------------------------------------------
#
#    Connection on pins is
#
#  Pmod pin  |    logic analyzer      |     FPGA signal     | FPGA Location
#  -------------------------------------------------------------------------
#    pin01   |                        |      cpu_reset_n    |     V27
#    pin02   |                        |       logic_set     |     Y30
#    pin03   |                        |      logic_reset    |     V24
#    pin04   |                        |         -           |      -
#    pin05   |          GND           |         -           |      -
#    pin06   |          VCC           |         -           |      -
#  -------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports dbg_cpu_reset_n];
set_property -dict {PACKAGE_PIN Y30 IOSTANDARD LVCMOS33} [get_ports dbg_logic_set];
set_property -dict {PACKAGE_PIN V24 IOSTANDARD LVCMOS33} [get_ports dbg_logic_reset];
