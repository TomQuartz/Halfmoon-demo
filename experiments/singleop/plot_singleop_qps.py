#!/usr/bin/python3
import os
import parse
import argparse
import numpy as np
import matplotlib.pyplot as plt


def summary(baseline, exp_name):
    base_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), baseline, "results")
    exp_dir = os.path.join(base_dir, exp_name)
    with open(os.path.join(exp_dir, "latency.txt")) as f:
        lines = f.read().strip().split("\n")
        read_p50, read_p99 = parse.parse("read latency: p50={:f}ms p99={:f}ms", lines[0])
        write_p50, write_p99 = parse.parse("write latency: p50={:f}ms p99={:f}ms", lines[1])
    return read_p50, read_p99, write_p50, write_p99

def plot(data, qps, figname):
    font_size = 20
    markersize = 10
    linewidth = 3
    plt.rc("font", **{"size": font_size})
    metrics = ["p50", "p99"]  # avg
    ylabels = ["Median latency (ms)", "99% latency (ms)"]
    fig, axs = plt.subplots(nrows=2, ncols=2, figsize=(20, 10))
    for ax in axs.flat:
        ax.get_yaxis().set_tick_params(direction="in")
        ax.get_xaxis().set_tick_params(direction="in", pad=8)
        ax.grid(True)
    for i in range(2):
        axs[-1][i].set_xlabel("Throughput (requests/s)", labelpad=8)
    for i, ax in enumerate(axs):
        ax[0].set_ylabel(ylabels[i], labelpad=8, fontsize=font_size)
    plt.subplots_adjust(hspace=0.18, wspace=0.18)

    ######################################## hotel
    labels = ["Unsafe", "Boki", "HM-read", "HM-write"]
    markers = ["s", "^", "o", "d"]
    colors = ["royalblue", "red", "lightsalmon", "lightcoral"]
    xticks = qps

    # plot
    handles = None
    for i, metric in enumerate(metrics):
        curves = []
        for j, baseline in enumerate(labels):
            (curve,) = axs[i][0].plot(
                xticks,
                data[f"read_{metric}"][j],
                label=labels[j],
                marker=markers[j],
                markersize=markersize,
                markeredgecolor="k",
                color=colors[j],
                linestyle="--",
                linewidth=linewidth,
            )
            (curve,) = axs[i][1].plot(
                xticks,
                data[f"write_{metric}"][j],
                label=labels[j],
                marker=markers[j],
                markersize=markersize,
                markeredgecolor="k",
                color=colors[j],
                linestyle="--",
                linewidth=linewidth,
            )
            curves.append(curve)
        axs[i][0].set_xticks(xticks)
        axs[i][1].set_xticks(xticks)
        if handles is None:
            handles = curves

    ############################################ legend
    legend_size = 20
    legend_length = 2
    bbox_to_anchor = (0.5, 1.0)
    fig.legend(
        handles=handles,
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
    parser.add_argument("--qps", nargs="+", type=int, default=[200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800])
    parser.add_argument("--size", type=int, default=256)
    parser.add_argument("run", metavar="run", type=int, default=1)
    args = parser.parse_args()
    run = args.run

    params = [("baseline",None),("boki",None),("optimal","write"),("optimal","read")]
    result = {"read_p50": [], "read_p99": [], "write_p50": [], "write_p99": []}
    for baseline, log_mode in params:
        read_p50 = []
        read_p99 = []
        write_p50 = []
        write_p99 = []
        for qps in args.qps:
            exp_name = f"QPS{qps}"
            if log_mode is not None:
                exp_name += f"_{log_mode}"
            exp_name += f"_v{args.size}_{run}"
            r50,r99,w50,w99 = summary(baseline, exp_name)
            read_p50.append(r50)
            read_p99.append(r99)
            write_p50.append(w50)
            write_p99.append(w99)
        result["read_p50"].append(read_p50)
        result["read_p99"].append(read_p99)
        result["write_p50"].append(write_p50)
        result["write_p99"].append(write_p99)
    for i in range(len(result["read_p50"][0])):
        print((result["read_p50"][1][i] - result["read_p50"][0][i]) / (result["read_p50"][2][i] - result["read_p50"][0][i]))
    # plot(result, args.qps, f"{run}_v{args.size}/microbenchmarks.png")
