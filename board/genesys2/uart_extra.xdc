# Extra UART on Genesys2 board connected to PMOD JC connector, which is
# an FTDI232 chip. The FT chip on the PCB has a jumper that dictates whether
# or not to power the FPGA board. It should be set to LCL.
# (The attached system board is powered independently from the Pmod USBUART.)
#
#    VCC      GND     ========     SIGNALS    ========
#   --------------------------------------------------
#   pin06    pin05    pin04    pin03    pin02    pin01
#   pin12    pin11    pin10    pin09    pin08    pin07
#   --------------------------------------------------
#
#    Connection on pins is
#
#  Pmod pin  |  Pmod USB-UART signal  |     FPGA signal     | FPGA Location
#  -------------------------------------------------------------------------
#    pin01   |       ~RTS             | usb_uart_extra_ctsn |     AC26
#    pin02   |        RXD             | usb_uart_extra_txd  |     AJ27
#    pin03   |        TXD             | usb_uart_extra_rxd  |     AH30
#    pin04   |       ~CTS             | usb_uart_extra_rtsn |     AK29
#    pin05   |        GND             |         -           |       -
#    pin06   |        VCC             |         -           |       -
#  -------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_ctsn];
set_property -dict {PACKAGE_PIN AJ27 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_txd];
set_property -dict {PACKAGE_PIN AH30 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_rxd];
set_property -dict {PACKAGE_PIN AK29 IOSTANDARD LVCMOS33} [get_ports usb_uart_extra_rtsn];
