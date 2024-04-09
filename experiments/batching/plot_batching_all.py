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


def plot(data, qps, read_ratios, batch_size, figname):
    font_size = 20
    markersize = 10
    width = 0.3
    plt.rc("font", **{"size": font_size})
    metrics = ["p50", "p99", "avg"]
    ylabels = ["Median latency (ms)", "99% latency (ms)", "Average latency (ms)"]
    fig, axs = plt.subplots(nrows=3, ncols=2, figsize=(12, 13))
    for i, ax in enumerate(axs):
        ax[0].set_ylabel(ylabels[i], labelpad=8, fontsize=font_size)
    plt.subplots_adjust(hspace=0.18, wspace=0.18)

    labels = ["Boki", "HM-read", "HM-write", "HM-read (batching)", "HM-write (batching)"]
    xlabels = [
        ["Boki", "HM-R.", "HM-R.\n(bs=2)", "HM-R.\n(bs=4)", "HM-R.\n(bs=8)"],
        ["Boki", "HM-W.", "HM-W.\n(bs=2)", "HM-W.\n(bs=4)", "HM-W.\n(bs=8)"],
    ]
    markers = ["^", "o", "d", "o", "d"]
    edgecolors = [
        ["red", "lightcoral", "lightcoral", "lightcoral", "lightcoral"],
        ["red", "lightsalmon", "lightsalmon", "lightsalmon", "lightsalmon"],
    ]
    colors = [
        ["red", "lightcoral", "white", "white", "white"],
        ["red", "lightsalmon", "white", "white", "white"],
    ]
    hatches = [
        ['', '', '//', '//', '//'],
        ['', '', '\\\\', '\\\\', '\\\\'],
    ]
    xticks = (np.arange(0, 5, 1) + 1) / 2

    for i, metric in enumerate(metrics):
        for j in range(2):
            latency = []
            for k, baseline in enumerate(labels):
                if j == 0 and (baseline == "HM-write" or baseline == "HM-write (batching)"):
                    continue
                if j == 1 and (baseline == "HM-read" or baseline == "HM-read (batching)"):
                    continue
                if baseline == "HM-read" or baseline == "HM-write" or baseline == "Boki":
                    latency.append(data[baseline][metric][j][0] - data["Unsafe"][metric][j][0])
                else:
                    for l in range(3):
                        latency.append(data[baseline][metric][j][l] - data["Unsafe"][metric][j][l])
            axs[i][j].bar(xticks, latency, color=colors[j], width=width, align='center', hatch=hatches[j], edgecolor=edgecolors[j])

        for j in range(2):
            axs[i][j].grid(False)
            axs[i][j].spines['top'].set_visible(False)
            axs[i][j].spines['right'].set_visible(False)
            axs[i][j].yaxis.set_ticks_position('left')
            axs[i][j].set_ylim(bottom=0)
            axs[i][j].get_yaxis().set_tick_params(direction='in', pad=5)
            axs[i][j].set_xticks(xticks)
            axs[i][j].set_xticklabels(xlabels[j], fontsize=15)
            axs[i][j].xaxis.set_ticks_position('bottom')

    fig_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), "figures")
    fig_path = os.path.join(fig_dir, figname)
    os.makedirs(os.path.dirname(fig_path), exist_ok=True)
    plt.savefig(os.path.join(fig_dir, figname), bbox_inches="tight", transparent=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--read-ratios", nargs="+", type=float, default=[0.1, 0.9])
    parser.add_argument("--qps", nargs="+", type=int, default=[50])
    parser.add_argument("--value-size", type=int, default=256)
    parser.add_argument("--batch-size", nargs="+", type=int, default=[2, 4, 8])
    parser.add_argument("run", metavar="run", type=int, default=0)
    args = parser.parse_args()
    run = args.run

    results = {}
    baselines = [
        ("baseline", None, "Unsafe"),
        ("boki", None, "Boki"),
        ("optimal", "write", "HM-read"),
        ("optimal", "read", "HM-write"),
        ("optimal-batch", "write", "HM-read (batching)"),
        ("optimal-batch", "read", "HM-write (batching)"),
    ]

    for baseline, logmode, name in baselines:
        result = {"p50": [], "p99": [], "avg": []}
        for qps in args.qps:
            for rr in args.read_ratios:
                result_p50 = []
                result_p99 = []
                result_avg = []
                for bs in args.batch_size:
                    if name == "HM-read (batching)":
                        rr = 0.1
                    elif name == "HM-write (batching)":
                        rr = 0.9
                    exp_name = f"ReadRatio{rr}_QPS{qps}_ops40"
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
    plot(results, args.qps, args.read_ratios, args.batch_size, f"{run}/batching_QPS{args.qps[0]}_2.png")
