#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
import os
import parse

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

if __name__ == "__main__":
    run = 21
    batch = [2, 4, 8, 24]

    unsafe_read_p50, unsafe_read_p99, _ = summary("baseline", "ReadRatio0.2_QPS5_ops30", run)
    unsafe_write_p50, unsafe_write_p99, _ = summary("baseline", "ReadRatio0.8_QPS5_ops30", run)
    boki_read_p50, boki_read_p99, _ = summary("boki", "ReadRatio0.2_QPS5_ops30", run)
    boki_write_p50, boki_write_p99, _ = summary("boki", "ReadRatio0.8_QPS5_ops30", run)
    optimal_read_p50, optimal_read_p99, _ = summary("optimal", "ReadRatio0.2_QPS5_ops30_write", run)
    optimal_write_p50, optimal_write_p99, _ = summary("optimal", "ReadRatio0.8_QPS5_ops30_read", run)

    unsafe_read_p50 = np.array([unsafe_read_p50])
    unsafe_read_p99 = np.array([unsafe_read_p99])
    unsafe_write_p50 = np.array([unsafe_write_p50])
    unsafe_write_p99 = np.array([unsafe_write_p99])
    # boki, optimal, optimal(bs=2), optimal(bs=4), optimal(bs=8)
    read_p50 = np.array([boki_read_p50, optimal_read_p50])
    read_p99 = np.array([boki_read_p99, optimal_read_p99])
    write_p50 = np.array([boki_write_p50, optimal_write_p50])
    write_p99 = np.array([boki_write_p99, optimal_write_p99])

    for bs in batch:
        optimal_batch_read_p50, optimal_batch_read_p99, _ = summary(
            "optimal-batch", f"ReadRatio0.2_QPS5_ops30_bs{bs}_write", run)
        optimal_batch_write_p50, optimal_batch_write_p99, _ = summary(
            "optimal-batch", f"ReadRatio0.8_QPS5_ops30_bs{bs}_read", run)
        read_p50 = np.append(read_p50, optimal_batch_read_p50)
        read_p99 = np.append(read_p99, optimal_batch_read_p99)
        write_p50 = np.append(write_p50, optimal_batch_write_p50)
        write_p99 = np.append(write_p99, optimal_batch_write_p99)

    print("unsafe")
    print(unsafe_read_p50, unsafe_read_p99, unsafe_write_p50, unsafe_write_p99)

    print("read_p50", read_p50)
    print("read_p99", read_p99)
    print("write_p50", write_p50)
    print("write_p99", write_p99)

    read_p50 = read_p50 - unsafe_read_p50
    read_p99 = read_p99 - unsafe_read_p99
    write_p50 = write_p50 - unsafe_write_p50
    write_p99 = write_p99 - unsafe_write_p99

    font_size = 15
    plt.rc('font',**{'size': font_size, 'family': 'Arial'})
    plt.rc('pdf',fonttype = 42)
    fig_size = (10, 8)
    fig, ax = plt.subplots(figsize=fig_size, nrows=2, ncols=2)
    width=0.4
    xticks=np.arange(0, 6, 1)+1
    xlabels = [
        ["Boki", "HM-R.", "HM-R.\n(bs=2)", "HM-R.\n(bs=4)", "HM-R.\n(bs=8)", "HM-R.\n(bs=24)"],
        ["Boki", "HM-W.", "HM-W.\n(bs=2)", "HM-W.\n(bs=4)", "HM-W.\n(bs=8)", "HM-W.\n(bs=24)"],
    ]
    edgecolors = [
        ["red", "lightsalmon", "lightsalmon", "lightsalmon", "lightsalmon", "lightsalmon"],
        ["red", "lightcoral", "lightcoral", "lightcoral", "lightcoral", "lightcoral"],
    ]
    colors = [
        ["white", "white", "white", "white", "white", "white"],
        ["white", "white", "white", "white", "white", "white"],
    ]
    hatches = [
        ['/\\', '//', '//', '//', '//', '//'],
        ['/\\', '\\\\', '\\\\', '\\\\', '\\\\', '\\\\'],
    ]
    # read
    ax[0][0].bar(xticks, read_p50[:6], color=colors[0], edgecolor=edgecolors[0], hatch=hatches[0], width=width, align='center')
    ax[1][0].bar(xticks, read_p99[:6], color=colors[0], edgecolor=edgecolors[0], hatch=hatches[0], width=width, align='center')
    # write
    ax[0][1].bar(xticks, write_p50[:6], color=colors[1], edgecolor=edgecolors[1], hatch=hatches[1], width=width, align='center')
    ax[1][1].bar(xticks, write_p99[:6], color=colors[1], edgecolor=edgecolors[1], hatch=hatches[1], width=width, align='center')
    # ticks
    ylabel="Median Latency (ms)"
    ax[0][0].set_ylabel(ylabel, labelpad=8)
    ylabel="99% latency (ms)"
    ax[1][0].set_ylabel(ylabel, labelpad=8)
    for i in range(len(ax)):
        for j in range(len(ax[i])):
            ax[i][j].spines['top'].set_visible(False)
            ax[i][j].spines['right'].set_visible(False)
            ax[i][j].yaxis.set_ticks_position('left')
            ax[i][j].set_ylim(bottom=0)
            # ax.set_yticks(y_ticks)
            ax[i][j].get_yaxis().set_tick_params(direction='in', pad=5)
            ax[i][j].set_xticks(xticks)
            ax[i][j].set_xticklabels(xlabels[j], fontsize=11)
            # ax[i].set_xticklabels(xlabels)
            ax[i][j].xaxis.set_ticks_position('bottom')
    fig.subplots_adjust(hspace=0.2, wspace=0.2)
    # plt.show()
    os.makedirs(f"./figures/{run}", exist_ok=True)
    file_path = f'./figures/{run}/batching.png'
    plt.savefig(file_path, bbox_inches='tight', transparent=False)
