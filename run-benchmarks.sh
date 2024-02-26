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
BENCHMARK_MIN_RUNTIME[adpcm_dec]=1
BENCHMARK_MIN_RUNTIME[adpcm_enc]=1
BENCHMARK_MIN_RUNTIME[ammunition]=120
BENCHMARK_MIN_RUNTIME[anagram]=2
BENCHMARK_MIN_RUNTIME[audiobeam]=3
BENCHMARK_MIN_RUNTIME[cjpeg_transupp]=2
BENCHMARK_MIN_RUNTIME[cjpeg_wrbmp]=1
BENCHMARK_MIN_RUNTIME[dijkstra]=15
BENCHMARK_MIN_RUNTIME[epic]=15
BENCHMARK_MIN_RUNTIME[fmref]=5
BENCHMARK_MIN_RUNTIME[g723_enc]=1
BENCHMARK_MIN_RUNTIME[gsm_dec]=2
BENCHMARK_MIN_RUNTIME[gsm_enc]=5
BENCHMARK_MIN_RUNTIME[h264_dec]=1
BENCHMARK_MIN_RUNTIME[huff_dec]=1
BENCHMARK_MIN_RUNTIME[huff_enc]=2
BENCHMARK_MIN_RUNTIME[mpeg2]=60
BENCHMARK_MIN_RUNTIME[ndes]=1
BENCHMARK_MIN_RUNTIME[petrinet]=1
BENCHMARK_MIN_RUNTIME[rijndael_dec]=10
BENCHMARK_MIN_RUNTIME[rijndael_enc]=10
BENCHMARK_MIN_RUNTIME[statemate]=1
BENCHMARK_MIN_RUNTIME[susan]=25

# Run all bencmarks in alphabetical order.
function run_benchmarks () {
    for BENCH in adpcm_dec \
                 adpcm_enc \
                 ammunition \
                 anagram \
                 audiobeam \
                 cjpeg_transupp \
                 cjpeg_wrbmp \
                 dijkstra \
                 epic \
                 fmref \
                 g723_enc \
                 gsm_dec \
                 gsm_enc \
                 h264_dec \
                 huff_dec \
                 huff_enc \
                 mpeg2 \
                 ndes \
                 petrinet \
                 rijndael_dec \
                 rijndael_enc \
                 statemate \
                 susan
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

for CONFIG in rv32_i16k_d16k \
              rv32_i16k_d256b \
              rv32_i16k_d8k \
              rv32_i1k_d1k \
              rv32_i1k_d2k \
              rv32_i1k_d512b \
              rv32_i256b_d16k \
              rv32_i2k_d1k \
              rv32_i2k_d2k \
              rv32_i2k_d4k \
              rv32_i4k_d2k \
              rv32_i4k_d4k \
              rv32_i4k_d8k \
              rv32_i512b_d1k \
              rv32_i512b_d512b \
              rv32_i512b_d8k \
              rv32_i8k_d16k \
              rv32_i8k_d4k \
              rv32_i8k_d512b \
              rv32_i8k_d8k
do
    export BENCHMARK_CONFIG=$CONFIG
    export BITSTREAM=workspace/${BENCHMARK_CONFIG}/${BITSTREAM_DIR}/${BITSTREAM_FILE}
    make -e program_device
    sleep 0.5
    run_benchmarks
done
