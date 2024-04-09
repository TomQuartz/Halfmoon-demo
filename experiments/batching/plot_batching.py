import matplotlib.pyplot as plt
import numpy as np
import os

unsafe_read_p50 = np.array([106.48])
unsafe_read_p99 = np.array([172.80])
unsafe_write_p50 = np.array([73.43])
unsafe_write_p99 = np.array([137.85])
# boki, optimal, optimal(bs=2), optimal(bs=4), optimal(bs=8)
read_p50 = np.array([212.89, 209.78, 182.11, 154.63, 146.33])
read_p99 = np.array([266.87, 265.30, 238.00, 223.91, 217.32])
write_p50 = np.array([123.62, 112.63, 98.28, 90.56, 81.55])
write_p99 = np.array([176.53, 159.55, 146.15, 141.91, 137.99])
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
xticks=np.arange(0, 5, 1)+1
xlabels = [
    ["Boki", "HM-R.", "HM-R.(bs=2)", "HM-R.(bs=4)", "HM-R.(bs=8)"],
    ["Boki", "HM-W.", "HM-W.(bs=2)", "HM-W.(bs=4)", "HM-W.(bs=8)"],
]
colors = [
    ["red", "lightsalmon", "limegreen", "limegreen", "limegreen"],
    ["red", "lightcoral", "lightseagreen", "lightseagreen", "lightseagreen"],
]
# read
ax[0][0].bar(xticks, read_p50[:5], color=colors[0], width=width, align='center')
ax[1][0].bar(xticks, read_p99[:5], color=colors[0], width=width, align='center')
# write
ax[0][1].bar(xticks, write_p50[:5], color=colors[1], width=width, align='center')
ax[1][1].bar(xticks, write_p99[:5], color=colors[1], width=width, align='center')
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
        ax[i][j].set_xticklabels(xlabels[j], rotation=45, ha="right", fontsize=13)
        # ax[i].set_xticklabels(xlabels)
        ax[i][j].xaxis.set_ticks_position('bottom')
fig.subplots_adjust(hspace=0.4, wspace=0.2)
# plt.show()
file_path = './figures/batching.pdf'
plt.savefig(file_path, bbox_inches='tight', transparent=True)
