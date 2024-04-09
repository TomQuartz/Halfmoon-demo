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


def plot(data, qps, read_ratios, figname):
    font_size = 20
    markersize = 10
    linewidth = 3
    plt.rc("font", **{"size": font_size})
    metrics = ["p50", "p99", "avg"]
    ylabels = ["Median latency (ms)", "99% latency (ms)", "Average latency (ms)"]
    fig, axs = plt.subplots(nrows=3, ncols=4, figsize=(40, 15))
    for ax in axs.flat:
        ax.get_yaxis().set_tick_params(direction="in")
        ax.get_xaxis().set_tick_params(direction="in", pad=8)
        ax.grid(True)
    for i in range(4):
        axs[-1][i].set_xlabel("Read Ratio", labelpad=8)
    for i, ax in enumerate(axs):
        ax[0].set_ylabel(ylabels[i], labelpad=8, fontsize=font_size)
    plt.subplots_adjust(hspace=0.18, wspace=0.18)

    labels = ["Boki", "HM-read", "HM-write", "HM-read (batching)", "HM-write (batching)"]
    markers = ["^", "o", "d", "o", "d"]
    colors = ["red", "lightcoral", "lightsalmon", "lightcoral", "lightsalmon"]
    linestyles = [":", "-", "-", "--", "--"]
    xticks = read_ratios

    handles = None
    for k in range(4):
        for i, metric in enumerate(metrics):
            curves = []
            for j, baseline in enumerate(labels):
                (curve,) = axs[i][k].plot(
                    xticks,
                    data[baseline][metric][k],
                    label=labels[j],
                    marker=markers[j],
                    markersize=markersize,
                    markeredgecolor="k",
                    color=colors[j],
                    linestyle=linestyles[j],
                    linewidth=linewidth,
                )
                curves.append(curve)
            axs[i][k].set_xticks(xticks)
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
    parser.add_argument("--read-ratios", nargs="+", type=float, default=[0.1, 0.3, 0.5, 0.7, 0.9])
    parser.add_argument("--qps", nargs="+", type=int, default=[10])
    parser.add_argument("--value-size", type=int, default=256)
    parser.add_argument("--batch-size", nargs="+", type=int, default=[2, 4, 6, 8])
    parser.add_argument("run", metavar="run", type=int, default=0)
    args = parser.parse_args()
    run = args.run

    results = {}
    baselines = [
        ("boki", None, "Boki"),
        ("optimal", "write", "HM-read"),
        ("optimal", "read", "HM-write"),
        ("optimal-batch", "write", "HM-read (batching)"),
        ("optimal-batch", "read", "HM-write (batching)"),
    ]

    for baseline, logmode, name in baselines:
        result = {"p50": [], "p99": [], "avg": []}
        for qps in args.qps:
            for bs in args.batch_size:
                result_p50 = []
                result_p99 = []
                result_avg = []
                for rr in args.read_ratios:
                    exp_name = f"ReadRatio{rr}_QPS{qps}_ops80"
                    if baseline == "optimal-batch":
                        exp_name += f"_bs{bs}"
                    if logmode is not None:
                        exp_name += f"_{logmode}"
                    p50, p99, avg = summary(baseline, exp_name, run)
                    result_p50.append(p50)
                    result_p99.append(p99)
                    result_avg.append(avg)
                result["p50"].append(result_p50)
                result["p99"].append(result_p99)
                result["avg"].append(result_avg)
        results[name] = result
    plot(results, args.qps, args.read_ratios, f"{run}/batching_QPS10.png")
