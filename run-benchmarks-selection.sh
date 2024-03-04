#!/bin/bash

# Prevent TERM warnings
export TERM=xterm-xfree86

# First source Vivado environment
VIVADO_VERSION=2022.2
VIVADO_HOME=/opt/xilinx/Vivado/${VIVADO_VERSION}
source ${VIVADO_HOME}/settings64.sh

TACLE_BENCH_DIR="../tacle-bench"
TACLE_BENCH_SEQ_DIR="$TACLE_BENCH_DIR/bench/sequential"

# Configure the benchmark minimal running times per benchmark,
# this is to make sure that each benchmark gets enough time to
# finish its execution (twice).
# This is configured per benchmark, in order to avoid unnecessary
# delays for small benchmarks.
declare -A BENCHMARK_MIN_RUNTIME
BENCHMARK_MIN_RUNTIME[adpcm_dec]=2
BENCHMARK_MIN_RUNTIME[adpcm_enc]=2
BENCHMARK_MIN_RUNTIME[g723_enc]=2
BENCHMARK_MIN_RUNTIME[h264_dec]=2
BENCHMARK_MIN_RUNTIME[huff_dec]=2
BENCHMARK_MIN_RUNTIME[ndes]=2
BENCHMARK_MIN_RUNTIME[petrinet]=2
BENCHMARK_MIN_RUNTIME[statemate]=2

# Run all bencmarks in alphabetical order.
function run_benchmarks () {
    for BENCH in adpcm_dec \
                 adpcm_enc \
                 g723_enc \
                 h264_dec \
                 huff_dec \
                 ndes \
                 petrinet \
                 statemate
    do
        # First compile the benchmark with an extra defined
        # macro that configures the correct riscv core config.
        # This core config will be printed to the termianl to
        # aid processing the output data.
        cd "$TACLE_BENCH_SEQ_DIR/$BENCH" \
            && make clean \
            && BENCHMARK_CONFIG=$BENCHMARK_CONFIG make \
            && cd -
        BENCHMARK_ELF="$TACLE_BENCH_SEQ_DIR/$BENCH/buildfiles/${BENCH}.elf"
        # Now connect to the riscv core and run the benchmark!
        xsdb ./run-single-benchmark.tcl $BENCHMARK_ELF ${BENCHMARK_MIN_RUNTIME[$BENCH]}
    done
}

export HW_DEVICE=xc7k325t_0
BITSTREAM_DIR=vivado-genesys2-riscv/genesys2-riscv.runs/impl_1
BITSTREAM_FILE=riscv_wrapper.bit

for CONFIG in rv32_i4k_d128b \
              rv32_i4k_d256b \
              rv32_i4k_d512b \
              rv32_i4k_d1k \
              rv32_i4k_d2k \
              rv32_i4k_d4k \
              rv32_i4k_d8k \
              rv32_i4k_d16k \
              rv32_i4k_d32k \
              rv32_i4k_d64k
do
    export BENCHMARK_CONFIG=$CONFIG
    export BITSTREAM=workspace/${BENCHMARK_CONFIG}/${BITSTREAM_DIR}/${BITSTREAM_FILE}
    make -e program_device
    sleep 0.5
    run_benchmarks
done
