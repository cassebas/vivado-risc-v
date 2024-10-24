# Extra UART on Genesys2 board connected to PMOD JC connector
#
#    VCC      GND     ========     SIGNALS    ========
#   --------------------------------------------------
#   pin06    pin05    pin04    pin03    pin02    pin01
#   pin12    pin11    pin10    pin09    pin08    pin07
#   --------------------------------------------------
#
#    Connection on pins is txd:pin01 rxd:pin02
#
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_txd];
set_property -dict {PACKAGE_PIN AJ27 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_rxd];
