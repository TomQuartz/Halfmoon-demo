#!/bin/bash

set -u

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

BENCH_IMAGE=emptyredbox/halfmoon-bench:test-v0

# Do I need them?
AWS_REGION=ap-southeast-1
NUM_KEYS=100
EXP_DIR=$BASE_DIR/results/QPS15
QPS=15
LOGMODE=read

WRK_DIR=~/wrk2

TABLE_PREFIX=$(head -c 64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TABLE_PREFIX="${TABLE_PREFIX}-"

ENGINE_HOSTS=("engine1" "engine2" "engine3")
SEQUENCER_HOSTS=("sequencer2" "sequencer3")
STORAGE_HOSTS=("storage1")
MANAGER_HOST="gateway1"
CLIENT_HOST="master1"
ENTRY_HOST="gateway1"
ALL_HOSTS=("${ENGINE_HOSTS[@]}" "${SEQUENCER_HOSTS[@]}" "${STORAGE_HOSTS[@]}" $MANAGER_HOST)

# assign labels and copy scripts to the corresponding nodes
for HOST in ${ENGINE_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=engine_node
    scp -q $BASE_DIR/k8s_files/engine_start.sh $HOST:/tmp/engine_start.sh
done
for HOST in ${SEQUENCER_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=sequencer_node
    scp -q $BASE_DIR/k8s_files/sequencer_start.sh $HOST:/tmp/sequencer_start.sh
done
for HOST in ${STORAGE_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=storage_node
    scp -q $BASE_DIR/k8s_files/storage_start.sh $HOST:/tmp/storage_start.sh
done

ssh -q $CLIENT_HOST -- docker pull $BENCH_IMAGE

ssh -q $CLIENT_HOST -- docker run -v /tmp:/tmp \
    $BENCH_IMAGE \
    cp -r /optimal-bin/singleop /tmp/

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX AWS_REGION=$AWS_REGION NUM_KEYS=$NUM_KEYS \
    /tmp/singleop/init create
ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX AWS_REGION=$AWS_REGION NUM_KEYS=$NUM_KEYS \
    /tmp/singleop/init populate

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
kubectl apply -f "$BASE_DIR/k8s_files/boki-storage.yaml"
kubectl apply -f "$BASE_DIR/k8s_files/boki-sequencer.yaml"
sleep 30
kubectl apply -f "$BASE_DIR/k8s_files/boki-controller.yaml"
kubectl apply -f "$BASE_DIR/k8s_files/app.yaml"
sleep 80

rm -rf $EXP_DIR
mkdir -p $EXP_DIR

ssh -q $MANAGER_HOST -- cat /proc/cmdline >>$EXP_DIR/kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >>$EXP_DIR/kernel_version

scp -q $ROOT_DIR/workloads/workflow/optimal/benchmark/singleop/workload.lua $CLIENT_HOST:/tmp
# scp -q $ROOT_DIR/workloads/workflow/optimal/benchmark/singleop/prewarm.lua $CLIENT_HOST:/tmp

# ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 10 -L -U \
#     -s /tmp/prewarm.lua \
#     http://$ENTRY_HOST:8080 -R 1 >$EXP_DIR/wrk_prewarm.log

# sleep 10

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 120 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS >$EXP_DIR/wrk_warmup.log

sleep 10

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 600 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS 2>/dev/null >$EXP_DIR/wrk.log

sleep 10

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX AWS_REGION=$AWS_REGION NUM_KEYS=$NUM_KEYS \
    /tmp/singleop/init clean
