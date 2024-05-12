#!/usr/bin/python3

import os
import parse
import argparse
import numpy as np
import matplotlib.pyplot as plt


def summary(baseline, exp_name, run):
    base_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), baseline, "results")
    run_dir = f"{exp_name}_{run}"
    exp_dir = os.path.join(base_dir, run_dir)
    with open(os.path.join(exp_dir, "latency.txt")) as f:
        lines = f.read().strip().split("\n")
        if len(lines) < 3:
            print(exp_dir)
            return
        line_p50, line_p99, line_avg = lines
        p50 = parse.parse("p50 latency: {:f} ms", line_p50)[0]
        p99 = parse.parse("p99 latency: {:f} ms", line_p99)[0]
        avg = parse.parse("avg latency: {:f} ms", line_avg)[0]
    return p50, p99, avg


def plot(data, qps, read_ratios, failure_rate, figname):
    font_size = 20
    markersize = 10
    width = 0.3
    plt.rc("font", **{"size": font_size})
    metrics = ["avg"]
    ylabels = ["Average latency (ms)"]
    fig, axs = plt.subplots(nrows=1, ncols=6, figsize=(36, 5))
    axs[0].set_ylabel(ylabels[0], labelpad=8, fontsize=font_size)
    plt.subplots_adjust(hspace=0.18, wspace=0.18)

    labels = ["Boki", "Halfmoon-read", "Halfmoon-write"]
    xlabels = [f"f={fr}" for fr in failure_rate]
    edgecolors = ["red", "lightcoral", "lightsalmon"]
    hatches = ['/\\', '//', '\\\\']
    xticks = np.arange(4)
    x = np.arange(4)
    total_width, n = 0.8, 3
    width = total_width / n
    x = x - (total_width - width) / 2

    for i, metric in enumerate(metrics):
        for l in range(len(read_ratios)):
            for k, baseline in enumerate(labels):
                latency = []
                for j in range(len(failure_rate)):
                    latency.append(data[baseline][l][j])
                axs[l].bar(x + k * width, latency, color="white", width=width, align='center', hatch=hatches[k], edgecolor=edgecolors[k])

    for l in range(len(read_ratios)):
        axs[l].grid(False)
        axs[l].spines['top'].set_visible(False)
        axs[l].spines['right'].set_visible(False)
        axs[l].yaxis.set_ticks_position('left')
        axs[l].set_ylim(bottom=0)
        axs[l].get_yaxis().set_tick_params(direction='in', pad=5)
        axs[l].set_xticks(xticks)
        axs[l].set_xticklabels(xlabels, fontsize=15)
        axs[l].xaxis.set_ticks_position('bottom')

    legend_size = 15
    legend_length = 2
    bbox_to_anchor = (0.5, 1.0)
    fig.legend(
        # handles=handles,
        labels=labels,
        handlelength=legend_length,
        ncol=len(labels),
        loc="upper center",
        bbox_to_anchor=bbox_to_anchor,
        frameon=True,
        prop={"size": legend_size},
    )

    fig_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "figures")
    fig_path = os.path.join(fig_dir, figname)
    os.makedirs(os.path.dirname(fig_path), exist_ok=True)
    plt.savefig(os.path.join(fig_dir, figname), bbox_inches="tight", transparent=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--read-ratios", nargs="+", type=float, default=[0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
    parser.add_argument("--qps", nargs="+", type=int, default=[100])
    parser.add_argument("--value-size", type=int, default=256)
    parser.add_argument("--failure-rate", nargs="+", type=float, default=[0.1, 0.2, 0.3, 0.4])
    parser.add_argument("run", metavar="run", type=int, default=0)
    args = parser.parse_args()
    run = args.run

    results = {}
    baselines = [
        ("boki", None, "Boki"),
        ("optimal", "write", "Halfmoon-read"),
        ("optimal", "read", "Halfmoon-write"),
    ]

    for baseline, logmode, name in baselines:
        result = []
        for qps in args.qps:
            for rr in args.read_ratios:
                result_avg = []
                for fr in args.failure_rate:
                    exp_name = f"ReadRatio{rr}_QPS{qps}"
                    if logmode is not None:
                        exp_name += f"_{logmode}"
                    exp_name += f"_v{args.value_size}_f{fr}"
                    _, _, avg = summary(baseline, exp_name, run)
                    result_avg.append(avg)
                result.append(result_avg)
        results[name] = result
    plot(results, args.qps, args.read_ratios, args.failure_rate, f"{run}/recovery.png")
