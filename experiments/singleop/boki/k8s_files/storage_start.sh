#!/bin/bash

NODE_ID=$(cat /tmp/node_name | grep -oE '[0-9]+$')
echo "export FAAS_NODE_ID=$NODE_ID" >> ~/.bashrc
source ~/.bashrc

FAAS_NODE_ID=$NODE_ID /boki/storage \
    --zookeeper_host=10.96.128.128:2181 \
    --listen_iface=eth0 \
    --db_path=/tmp/storage/logdata \
    --num_io_workers=2 \
    --io_uring_entries=2048 \
    --io_uring_fd_slots=4096 \
    --slog_local_cut_interval_us=300 \
    --slog_storage_bgthread_interval_ms=1 \
    --slog_storage_backend=rocksdb \
    --slog_storage_cache_cap_mb=4096 \
    # --use_txn_engine \
    # --v=1
