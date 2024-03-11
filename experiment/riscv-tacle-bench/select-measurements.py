import pandas as pd
import click
import click_log
import logging
import glob
from os.path import isdir, join

logger = logging.getLogger(__name__)
click_log.basic_config(logger)

cache_configurations = {
    # name : (sets, ways, bytes)
    "128b" : (2, 1, 128),
    "256b" : (4, 1, 256),
    "512b" : (8, 1, 512),
    "1k"   : (16, 1, 1024),
    "2k"   : (32, 1, 2048),
    "4k"   : (64, 1, 4096),
    "8k"   : (64, 2, 8192),
    "16k"  : (64, 4, 16384),
    "32k"  : (128, 4, 32768),
    "64k"  : (256, 4, 65536),
}

def select_measurements(input_dir, output_dir):
    # Get all input files in the current directory
    inputfiles = sorted(glob.glob(join(input_dir,
                                       "rv32-complete-*.csv")))

    for inputfile in inputfiles:
        logger.info("Reading input file {}".format(inputfile))
        df = pd.read_csv(inputfile, sep=',')
        df.insert(2, 'icache_size', 0)
        df.insert(3, 'dcache_size', 0)
        benchmark_list = df['benchmark'].unique()
        if len(benchmark_list) != 1:
            logger.warn("Number of benchmarks in input file {} ".format +
                        "is not equal to 1!")
        bm = benchmark_list[0]

        # First experiment, for each i-cache size growing size of d-caches
        for icache_conf in cache_configurations.keys():
            cache_configs = []
            for dcache_conf in cache_configurations.keys():
                this_cc = "i{}_d{}".format(icache_conf, dcache_conf)
                (ics, icw, icb) = cache_configurations[icache_conf]
                (dcs, dcw, dcb) = cache_configurations[dcache_conf]
                df.loc[df.cache_config == this_cc, "icache_size"] = icb
                df.loc[df.cache_config == this_cc, "dcache_size"] = dcb
                cache_configs.append(this_cc)

            # Filter the dataframe
            mask = df['cache_config'].isin(cache_configs)
            expdf = df[mask]

            # Now make sure that there will only be one value per configuration
            columns = expdf.columns.values.tolist()
            aggfunc = {}
            for c in columns:
                aggfunc[c] = 'last'
            aggfunc['cycles_cold_cache'] = 'median'
            aggfunc['cycles_warm_cache'] = 'median'
            expdf = expdf.groupby(df.cache_config).aggregate(aggfunc)

            # Sort the dataframe
            expdf = expdf.sort_values('dcache_size')

            if len(expdf.index) < 10:
                # not enough measurements
                logger.warning("For benchmark {} ".format(bm) +
                               "and configuration i{} ".format(icache_conf) +
                               "there aren't enough measurements")
            else:
                # This is a filtered dataframe, output to CSV
                outputfile = join(output_dir,
                                "rv32-experiment-{}-1-i{}.csv".format(bm,
                                                                      icache_conf))
                logger.info("Writing to this output file: {}".format(outputfile))
                expdf.to_csv(outputfile, index=False, sep=",")

        # Second experiment, for each d-cache size growing size of i-caches
        for dcache_conf in cache_configurations.keys():
            cache_configs = []
            for icache_conf in cache_configurations.keys():
                this_cc = "i{}_d{}".format(icache_conf, dcache_conf)
                (ics, icw, icb) = cache_configurations[icache_conf]
                (dcs, dcw, dcb) = cache_configurations[dcache_conf]
                df.loc[df.cache_config == this_cc, "icache_size"] = icb
                df.loc[df.cache_config == this_cc, "dcache_size"] = dcb
                cache_configs.append(this_cc)

            # Filter the dataframe
            mask = df['cache_config'].isin(cache_configs)
            expdf = df[mask]

            # Now make sure that there will only be one value per configuration
            columns = expdf.columns.values.tolist()
            aggfunc = {}
            for c in columns:
                aggfunc[c] = 'last'
            aggfunc['cycles_cold_cache'] = 'median'
            aggfunc['cycles_warm_cache'] = 'median'
            expdf = expdf.groupby(df.cache_config).aggregate(aggfunc)

            # Sort the dataframe
            expdf = expdf.sort_values('icache_size')

            if len(expdf.index) < 10:
                # not enough measurements
                logger.warning("For benchmark {} ".format(bm) +
                               "and configuration d{} ".format(dcache_conf) +
                               "there aren't enough measurements")
            else:
                # This is a filtered dataframe, output to CSV
                outputfile = join(output_dir,
                                "rv32-experiment-{}-2-d{}.csv".format(bm,
                                                                      dcache_conf))
                logger.info("Writing to this output file: {}".format(outputfile))
                expdf.to_csv(outputfile, index=False, sep=",")

        # Third experiment, both i-cache size and d-cache size grow
        cache_configs = []
        for cache_conf in cache_configurations.keys():
            this_cc = "i{}_d{}".format(cache_conf, cache_conf)
            (ics, icw, icb) = cache_configurations[cache_conf]
            (dcs, dcw, dcb) = cache_configurations[cache_conf]
            df.loc[df.cache_config == this_cc, "icache_size"] = icb
            df.loc[df.cache_config == this_cc, "dcache_size"] = dcb
            cache_configs.append(this_cc)

        # Filter the dataframe
        mask = df['cache_config'].isin(cache_configs)
        expdf = df[mask]

        # Now make sure that there will only be one value per configuration
        columns = expdf.columns.values.tolist()
        aggfunc = {}
        for c in columns:
            aggfunc[c] = 'last'
        aggfunc['cycles_cold_cache'] = 'median'
        aggfunc['cycles_warm_cache'] = 'median'
        expdf = expdf.groupby(df.cache_config).aggregate(aggfunc)

        # Sort the dataframe
        expdf = expdf.sort_values('icache_size')

        if len(expdf.index) < 10:
            # not enough measurements
            logger.warning("For benchmark {} ".format(bm) +
                           "and growing cache configurations " +
                           "there aren't enough measurements")
        else:
            # This is a filtered dataframe, output to CSV
            outputfile = join(output_dir,
                              "rv32-experiment-{}-3.csv".format(bm))
            logger.info("Writing to this output file: {}".format(outputfile))
            expdf.to_csv(outputfile, index=False, sep=",")



@click.command()
@click.option('--input-dir',
              required=True,
              help=('Path of the directory where the CSV input files reside.'))
@click.option('--output-dir',
              required=True,
              help=('Path of the directory where the CSV output files ' +
                    'must be stored.'))
@click_log.simple_verbosity_option(logger)
def main(input_dir, output_dir):
    if not isdir(input_dir):
        logger.error("Error: input directory {} ".format(input_dir) +
                     "does not exist!")
    if not isdir(output_dir):
        logger.error("Error: ouput directory {} ".format(output_dir) +
                     "does not exist!")
        exit(1)

    select_measurements(input_dir, output_dir)


if __name__ == "__main__":
    main()


