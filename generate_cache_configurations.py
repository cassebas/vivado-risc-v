import click
import click_log
import logging
from os.path import isfile, isdir, join

logger = logging.getLogger(__name__)
click_log.basic_config(logger)

scala_header = """package Vivado
/**
 *******************************************
 *  THIS IS A GENERATED FILE, DO NOT EDIT! *
 *******************************************
 */
import Chisel._
import org.chipsalliance.cde.config.{Config, Parameters}
import freechips.rocketchip.devices.debug.DebugModuleKey
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.tile.{BuildRoCC, OpcodeSet}
import freechips.rocketchip.util.DontTouch
import freechips.rocketchip.system._
"""

sh_header = """#!/bin/sh

##########################################
# THIS IS A GENERATED FILE, DO NOT EDIT! #
##########################################

# First source Vivado environment
VIVADO_VERSION=2022.2
VIVADO_HOME=/opt/xilinx/Vivado/${VIVADO_VERSION}
source ${VIVADO_HOME}/settings64.sh

# Now make the bitstreams in batch mode"""

cache_configurations = {
    # name : (sets, ways)
    "64b"  : (1, 1),
    "128b" : (2, 1),
    "256b" : (4, 1),
    "512b" : (8, 1),
    "1k"   : (16, 1),
    "2k"   : (32, 1),
    "4k"   : (64, 1),
    "8k"   : (64, 2),
    "16k"  : (64, 4),
    "32k"  : (128, 4),
    "64k"  : (256, 4),
}

def output_header(header):
    print(header)

def generate_cache_configurations():
    for icache_conf in cache_configurations.keys():
        for dcache_conf in cache_configurations.keys():
            (i_cache_sets, i_cache_ways) = cache_configurations[icache_conf]
            (d_cache_sets, d_cache_ways) = cache_configurations[dcache_conf]
            cache_conf_str = "rv32_i{}_d{}".format(icache_conf, dcache_conf)
            print("class {} extends Config (".format(cache_conf_str))
            print("  new WithNBreakpoints(8) ++")
            print("  new WithL1ICacheSets({}) ++".format(i_cache_sets))
            print("  new WithL1ICacheWays({}) ++".format(i_cache_ways))
            print("  new WithL1DCacheSets({}) ++".format(d_cache_sets))
            print("  new WithL1DCacheWays({}) ++".format(d_cache_ways))
            print("  new WithNSmallCores(1) ++")
            print("  new WithRV32 ++")
            print("  new Rocket32BaseConfig)")
            print()

def generate_make_bitstream_commands():
    for icache_conf in cache_configurations.keys():
        for dcache_conf in cache_configurations.keys():
            (i_cache_sets, i_cache_ways) = cache_configurations[icache_conf]
            (d_cache_sets, d_cache_ways) = cache_configurations[dcache_conf]
            cache_conf_str = "rv32_i{}_d{}".format(icache_conf, dcache_conf)

            workspace_dir = "workspace/{}".format(cache_conf_str)
            impl_dir = "vivado-genesys2-riscv/genesys2-riscv.runs/impl_1"
            bitsream_file = "riscv_wrapper.bit"
            bitstream = "{}/{}/{}".format(workspace_dir, impl_dir, bitsream_file)
            print("if [ -f {} ]; then".format(bitstream))
            print("\techo \"Not making {},".format(cache_conf_str), end="")
            print(" already exists.\"")
            print("else")
            print("\techo \"Making {}\"".format(cache_conf_str))
            print("\tmake CONFIG={} BOARD={} bitstream".format(cache_conf_str,
                                                               "genesys2"))
            print("fi")


@click.command()
@click.option('--output-mode',
              required=True,
              help='Mode of the output, either scala or sh.')
@click_log.simple_verbosity_option(logger)
def main(output_mode):
    if not (output_mode == "scala" or output_mode == "sh"):
        logger.error("Output mode must be either '{}' or '{}'".format("scala",
                                                                      "sh"))
        logger.info('Exiting program due to error.')
        exit(1)

    if output_mode == "scala":
        output_header(scala_header)
        generate_cache_configurations()
    else:
        output_header(sh_header)
        generate_make_bitstream_commands()


if __name__ == "__main__":
    main()
