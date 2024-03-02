import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

df = pd.read_csv("tacle-bench-sequential-20240226.csv")

df_i8k = df[df['cache_config'].str.contains(r'i8k')]

sorted_cache_configs = ['rv32_i8k_d512b', 'rv32_i8k_d4k', 'rv32_i8k_d8k', 'rv32_i8k_d16k']
mapping = {config: i for i, config in enumerate(sorted_cache_configs)}
idx = dict(zip(sorted_cache_configs, range(len(sorted_cache_configs))))
config_series = df_i8k['cache_config'].map(idx)
dftmp = pd.DataFrame([config_series])
dftmp = dftmp.transpose()
dftmp.rename(columns={"cache_config":"cache_config_index"}, inplace=True)
df_i8k_idx = pd.concat([dftmp, df_i8k], axis=1)

biggest_benchmarks = ['ammunition', 'mpeg2', 'susan']
big_benchmarks = ['h264_dec', 'huff_dec', 'ndes']
middle_benchmarks = ['dijkstra', 'adpcm_dec', 'cjpeg_wrbmp']
small_benchmarks = ['adpcm_dec', 'adpcm_enc', 'epic']
tiny_benchmarks = ['fmref', 'petrinet']

df_i8k_biggest = df_i8k_idx[df_i8k_idx['benchmark'].isin(biggest_benchmarks)]
df_i8k_big = df_i8k_idx[df_i8k_idx['benchmark'].isin(big_benchmarks)]
df_i8k_middle = df_i8k_idx[df_i8k_idx['benchmark'].isin(middle_benchmarks)]
df_i8k_small = df_i8k_idx[df_i8k_idx['benchmark'].isin(small_benchmarks)]
df_i8k_tiny = df_i8k_idx[df_i8k_idx['benchmark'].isin(tiny_benchmarks)]

dfs_i8k_biggest = [df_i8k_biggest[df_i8k_biggest["cache_config_index"]==i] for i in range(4)]
dfs_i8k_big = [df_i8k_big[df_i8k_big["cache_config_index"]==i] for i in range(4)]
dfs_i8k_middle = [df_i8k_middle[df_i8k_middle["cache_config_index"]==i] for i in range(4)]
dfs_i8k_small = [df_i8k_small[df_i8k_small["cache_config_index"]==i] for i in range(4)]
dfs_i8k_tiny = [df_i8k_tiny[df_i8k_tiny["cache_config_index"]==i] for i in range(4)]

def draw_bar_plot(benchmark_list, df):
    width = 0.1
    fig, ax = plt.subplots(1, 1, sharey=True, figsize=(20,10))
    index = np.arange(len(benchmark_list))
    offset = -1.5
    labels = ["512B", "4KiB", "8KiB", "16KiB"]
    bars = []
    for i in range(4):
        ax.bar(index + offset*width, df[i].loc[:, "cycles_cold_cache"], width, labels[i])
        offset = offset + 1
    ax.legend(labels, fontsize=18)
    ax.set_xlabel('benchmark', fontsize=24)
    ax.set_ylabel('number of cycles', fontsize=24)
    ax.set_xticks(index)
    ax.set_xticklabels(benchmark_list, fontsize=20)
    ax.tick_params(labelrotation=0)


draw_bar_plot(tiny_benchmarks, dfs_i8k_tiny)
draw_bar_plot(small_benchmarks, dfs_i8k_small)
draw_bar_plot(middle_benchmarks, dfs_i8k_middle)
draw_bar_plot(big_benchmarks, dfs_i8k_big)
draw_bar_plot(biggest_benchmarks, dfs_i8k_biggest)
