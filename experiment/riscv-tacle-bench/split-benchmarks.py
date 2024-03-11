import pandas as pd
import click
import click_log
import logging
import glob
from os.path import isdir, join

logger = logging.getLogger(__name__)
click_log.basic_config(logger)


def split_benchmarks(input_dir, output_dir):
    # Get all input files in the current directory
    inputfiles = sorted(glob.glob(join(input_dir,
                                       "tacle-bench-sequential-*-?.csv")))
    logger.info("Working on these input files: {}".format(inputfiles))

    # First concat all CSV files together in a dataframe
    df = pd.DataFrame()
    dfs = pd.DataFrame()
    for inputfile in inputfiles:
        df = pd.read_csv(inputfile, sep=',')
        dfs = pd.concat([dfs, df])

    # Get list of benchmarks
    benchmark_list = dfs['benchmark'].unique()
    logger.info("Benchmarks found are: {}".format(benchmark_list))
    for bm in benchmark_list:
        # fdf is a filtered dataframe with only one benchmark
        fdf = dfs[dfs['benchmark']==bm].copy()

        # For now keep underscores and fix them later on with m4
        # # LaTeX doesn't handle underscore well, replace by dashes
        # fdf.loc[:,'cache_config'] = fdf['cache_config'].str.replace('_','-')
        # fdf.loc[:,'benchmark'] = fdf['benchmark'].str.replace('_','-')

        # Make an extra architecture column in the dataframe, with a default
        # value to make sure there will be no empty cells later on
        fdf.insert(0, 'architecture', 'unknown')

        # Fill in the correct architecture rv32 by selecting the rows that
        # start the cache config with rv32
        fdf.loc[fdf.cache_config.str.contains("rv32"), 'architecture'] = "rv32"

        # Now remove the architecture part of the cache_config column
        fdf.loc[:,'cache_config'] = fdf['cache_config'].str.replace('rv32_','')

        # Create CSV output file
        outputfile = join(output_dir,
                          "rv32-complete-{}.csv".format(bm))
        logger.info("Writing to this output file: {}".format(outputfile))
        fdf.to_csv(outputfile, index=False, sep=',')


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

    split_benchmarks(input_dir, output_dir)


if __name__ == "__main__":
    main()


