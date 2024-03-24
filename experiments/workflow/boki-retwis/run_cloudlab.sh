#!/bin/bash

set -u

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

BENCH_IMAGE=emptyredbox/halfmoon-bench:small-v0

EXP_DIR=$BASE_DIR/results/$1
QPS=$2
NUM_USERS=10000
NUM_FOLLOWERS=8
MAX_RETURN_POSTS=5

WRK_DIR=$ROOT_DIR/scripts

TABLE_PREFIX=$(head -c 64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TABLE_PREFIX="${TABLE_PREFIX}-"

ENGINE_HOSTS=("node1" "node2")
SEQUENCER_HOSTS=("node1" "node2")
STORAGE_HOSTS=("node1" "node2")
MANAGER_HOST="master"
CLIENT_HOST="master"
ENTRY_HOST="master"
ALL_HOSTS=("${ENGINE_HOSTS[@]}" "${SEQUENCER_HOSTS[@]}" "${STORAGE_HOSTS[@]}" $MANAGER_HOST)

# assign labels and copy scripts to the corresponding nodes
for HOST in ${ENGINE_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=engine_node --overwrite
    scp -q $BASE_DIR/k8s_files/engine_start.sh $HOST:/tmp/engine_start.sh
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/.aws 
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/.aws
    sudo scp -q $ROOT_DIR/scripts/.aws/credentials $HOST:/mnt/inmem/.aws/credentials
done
for HOST in ${SEQUENCER_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=sequencer_node --overwrite
    scp -q $BASE_DIR/k8s_files/sequencer_start.sh $HOST:/tmp/sequencer_start.sh
done
for HOST in ${STORAGE_HOSTS[@]}; do 
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=storage_node --overwrite
    scp -q $BASE_DIR/k8s_files/storage_start.sh $HOST:/tmp/storage_start.sh
done

ssh -q $CLIENT_HOST -- sudo docker pull $BENCH_IMAGE
ssh -q $CLIENT_HOST -- sudo rm -rf /tmp/singleop/
ssh -q $CLIENT_HOST -- sudo docker run -v /tmp:/tmp \
    $BENCH_IMAGE \
    cp -r /bokiflow-bin/retwis /tmp/

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX \
                       NUM_USERS=$NUM_USERS NUM_FOLLOWERS=$NUM_FOLLOWERS MAX_RETURN_POSTS=$MAX_RETURN_POSTS \
    /tmp/retwis/init create cayon
ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX \
                       NUM_USERS=$NUM_USERS NUM_FOLLOWERS=$NUM_FOLLOWERS MAX_RETURN_POSTS=$MAX_RETURN_POSTS \
    /tmp/retwis/init populate cayon

# Create a ConfigMap to store environment variables (TABLE_PREFIX)
kubectl create configmap env-config --from-literal=TABLE_PREFIX=$TABLE_PREFIX

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

scp -q $ROOT_DIR/workloads/workflow/boki/benchmark/retwis/workload.lua $CLIENT_HOST:/tmp

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 30 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS >$EXP_DIR/wrk_warmup.log

sleep 10

ssh -q $CLIENT_HOST -- $WRK_DIR/wrk -t 2 -c 2 -d 150 -L -U \
    -s /tmp/workload.lua \
    http://$ENTRY_HOST:8080 -R $QPS 2>/dev/null >$EXP_DIR/wrk.log

sleep 10

scp -q $MANAGER_HOST:/mnt/inmem/store/async_results $EXP_DIR
if [ -s "$EXP_DIR/async_results" ]; then
    $ROOT_DIR/scripts/compute_latency.py --async-result-file $EXP_DIR/async_results >$EXP_DIR/latency.txt
fi

ssh -q $CLIENT_HOST -- TABLE_PREFIX=$TABLE_PREFIX \
                       NUM_USERS=$NUM_USERS NUM_FOLLOWERS=$NUM_FOLLOWERS MAX_RETURN_POSTS=$MAX_RETURN_POSTS \
    /tmp/retwis/init clean cayon
