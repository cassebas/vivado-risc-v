#!/bin/sh

# First source Vivado environment
VIVADO_VERSION=2022.2
VIVADO_HOME=/opt/xilinx/Vivado/${VIVADO_VERSION}
source ${VIVADO_HOME}/settings64.sh

# Now make the bitstreams in batch mode
make CONFIG=rv32_i512b_d512b BOARD=genesys2 bitstream
make CONFIG=rv32_i1k_d512b BOARD=genesys2 bitstream
make CONFIG=rv32_i512b_d1k BOARD=genesys2 bitstream
make CONFIG=rv32_i1k_d1k BOARD=genesys2 bitstream
make CONFIG=rv32_i2k_d1k BOARD=genesys2 bitstream
make CONFIG=rv32_i1k_d2k BOARD=genesys2 bitstream
make CONFIG=rv32_i2k_d2k BOARD=genesys2 bitstream
make CONFIG=rv32_i4k_d2k BOARD=genesys2 bitstream
make CONFIG=rv32_i2k_d4k BOARD=genesys2 bitstream
make CONFIG=rv32_i4k_d4k BOARD=genesys2 bitstream
make CONFIG=rv32_i8k_d4k BOARD=genesys2 bitstream
make CONFIG=rv32_i4k_d8k BOARD=genesys2 bitstream
make CONFIG=rv32_i8k_d8k BOARD=genesys2 bitstream
make CONFIG=rv32_i16k_d8k BOARD=genesys2 bitstream
make CONFIG=rv32_i8k_d16k BOARD=genesys2 bitstream
make CONFIG=rv32_i16k_d16k BOARD=genesys2 bitstream
make CONFIG=rv32_i8k_d512b BOARD=genesys2 bitstream
make CONFIG=rv32_i512b_d8k BOARD=genesys2 bitstream
make CONFIG=rv32_i16k_d256b BOARD=genesys2 bitstream
make CONFIG=rv32_i256b_d16k BOARD=genesys2 bitstream
