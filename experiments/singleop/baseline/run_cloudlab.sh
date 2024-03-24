#!/bin/bash

set -u

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

BENCH_IMAGE=emptyredbox/halfmoon-bench:small-v0

NUM_KEYS=100
EXP_DIR=$BASE_DIR/results/$1
QPS=$2

WRK_DIR=$ROOT_DIR/scripts

TABLE_PREFIX=$(head -c 64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TABLE_PREFIX="${TABLE_PREFIX}-"

ENGINE_HOSTS=("node1" "node2")
SEQUENCER_HOSTS=("node1" "node2")
STORAGE_HOSTS=("node1" "node2")
MANAGER_HOST="node0"
CLIENT_HOST="node0"
ENTRY_HOST="node0"
ALL_HOSTS=("${ENGINE_HOSTS[@]}" "${SEQUENCER_HOSTS[@]}" "${STORAGE_HOSTS[@]}" $MANAGER_HOST)

# assign labels and copy scripts to the corresponding nodes
for HOST in ${ENGINE_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=engine_node
    scp -q $BASE_DIR/k8s_files/engine_start.sh $HOST:/tmp/engine_start.sh
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/.aws
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/.aws
    sudo scp -q $ROOT_DIR/scripts/.aws/credentials $HOST:/mnt/inmem/.aws/
done

ssh -q $CLIENT_HOST -- sudo docker pull $BENCH_IMAGE
ssh -q $CLIENT_HOST -- sudo rm -rf /tmp/bsingleop/
ssh -q $CLIENT_HOST -- sudo docker run -v /tmp:/tmp \
    $BENCH_IMAGE \
    cp -r /beldi-bin/bsingleop /tmp/

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX NUM_KEYS=$NUM_KEYS \
    /tmp/bsingleop/init create
ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX NUM_KEYS=$NUM_KEYS \
    /tmp/bsingleop/init populate

# Create a ConfigMap to store environment variables (TABLE_PREFIX, NUM_KEYS)
kubectl create configmap env-config --from-literal=TABLE_PREFIX=$TABLE_PREFIX --from-literal=NUM_KEYS=$NUM_KEYS

scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh
ssh -q $MANAGER_HOST -- sudo mkdir -p /mnt/inmem/store

for HOST in ${ALL_HOSTS[@]}; do
    scp -q $BASE_DIR/nightcore_config.json $HOST:/tmp/nightcore_config.json
done

for HOST in ${ENGINE_HOSTS[@]}; do
    scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
    ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
    ssh -q $HOST -- sudo cp /tmp/nightcore_config.json /mnt/inmem/boki/func_config.json
done

for HOST in ${STORAGE_HOSTS[@]}; do
    ssh -q $HOST -- sudo rm -rf   /mnt/storage/logdata
    ssh -q $HOST -- sudo mkdir -p /mnt/storage/logdata
done

sleep 10
# start zookeeper
kubectl apply -f "$BASE_DIR/k8s_files/zookeeper.yaml"
sleep 10
# set up zookeeper
kubectl apply -f "$BASE_DIR/k8s_files/zookeeper-setup.yaml"
sleep 30
kubectl apply -f "$BASE_DIR/k8s_files/boki-engine.yaml"
kubectl apply -f "$BASE_DIR/k8s_files/boki-gateway.yaml"
sleep 30
kubectl apply -f "$BASE_DIR/k8s_files/app.yaml"
sleep 80

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

scp -q $ROOT_DIR/workloads/workflow/beldi/benchmark/singleop/workload.lua $CLIENT_HOST:/tmp

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 120 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS >$EXP_DIR/wrk_warmup.log

sleep 10

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 600 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS 2>/dev/null >$EXP_DIR/wrk.log

sleep 10

scp -q $MANAGER_HOST:/mnt/inmem/store/async_results $EXP_DIR
$ROOT_DIR/scripts/singleop_latency.py --async-result-file $EXP_DIR/async_results >$EXP_DIR/latency.txt

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX NUM_KEYS=$NUM_KEYS \
    /tmp/bsingleop/init clean
