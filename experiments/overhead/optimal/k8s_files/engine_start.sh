#!/bin/bash

NODE_ID=$(echo "$NODE_NAME" | grep -oE '[0-9]+$')
echo "export FAAS_NODE_ID=$NODE_ID" >> ~/.bashrc
source ~/.bashrc

FAAS_NODE_ID=$NODE_ID /boki/engine \
    --zookeeper_host=10.96.128.128:2181 \
    --listen_iface=eth0 \
    --root_path_for_ipc=/tmp/boki/ipc \
    --func_config_file=/tmp/boki/func_config.json \
    --num_io_workers=4 \
    --instant_rps_p_norm=0.8 \
    --io_uring_entries=2048 \
    --io_uring_fd_slots=4096 \
    --enable_shared_log \
    --slog_engine_enable_cache \
    --slog_engine_cache_cap_mb=1024 \
    --use_txn_engine \
    # --slog_engine_propagate_auxdata \
    # --v=1
