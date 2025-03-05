#!/bin/bash

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/..`

IFS=',' read -r -a ENGINE_HOSTS <<< "$ENGINES"
IFS=',' read -r -a SEQUENCER_HOSTS <<< "$SEQUENCERS"
IFS=',' read -r -a STORAGE_HOSTS <<< "$STORAGES"

MANAGER_HOST=$GATEWAY
ENTRY_HOST=$GATEWAY

CLIENT_HOST=${CLIENT_HOST:-$(hostname)}

ALL_HOSTS=("${ENGINE_HOSTS[@]}" "${SEQUENCER_HOSTS[@]}" "${STORAGE_HOSTS[@]}" $MANAGER_HOST)

# setup aws credentials
mkdir -p ~/.aws
cp $BASE_DIR/credentials ~/.aws/credentials

# create a pod for database
kubectl apply -f "$BASE_DIR/k8s_files/db.yaml"
kubectl apply -f "$BASE_DIR/k8s_files/metrics.yaml"
sleep 40

TABLE_PREFIX=$(head -c 64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TABLE_PREFIX="${TABLE_PREFIX}-"

# assign labels and copy scripts to the corresponding nodes
engine_id=0
for HOST in ${ENGINE_HOSTS[@]}; do 
    engine_id=$((engine_id+1))
    echo engine$engine_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=engine_node --overwrite
    scp -q $BASE_DIR/k8s_files/engine_start.sh $HOST:/tmp/engine_start.sh
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/.aws
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/.aws
    sudo scp -q $BASE_DIR/credentials $HOST:/mnt/inmem/.aws/
done
sequencer_id=0
for HOST in ${SEQUENCER_HOSTS[@]}; do 
    sequencer_id=$((sequencer_id+1))
    echo sequencer$sequencer_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=sequencer_node --overwrite
    scp -q $BASE_DIR/k8s_files/sequencer_start.sh $HOST:/tmp/sequencer_start.sh
done
storage_id=0
for HOST in ${STORAGE_HOSTS[@]}; do 
    storage_id=$((storage_id+1))
    echo storage$storage_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=storage_node --overwrite
    scp -q $BASE_DIR/k8s_files/storage_start.sh $HOST:/tmp/storage_start.sh
done
kubectl label nodes $MANAGER_HOST node-restriction.kubernetes.io/placement_label=gateway_node --overwrite

scp -q $ROOT_DIR/scripts/zk_setup.sh $MANAGER_HOST:/tmp/zk_setup.sh
ssh -q $MANAGER_HOST -- sudo mkdir -p /mnt/inmem/store

for HOST in ${ALL_HOSTS[@]}; do
    scp -q $BASE_DIR/nightcore_config.json $HOST:/tmp/nightcore_config.json
done

for HOST in ${ENGINE_HOSTS[@]}; do
    # scp -q $BASE_DIR/run_launcher $HOST:/tmp/run_launcher
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki
    ssh -q $HOST -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
    # ssh -q $HOST -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
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
sleep 80

ssh -q $MANAGER_HOST -- cat /proc/cmdline >$BASE_DIR/.kernel_cmdline
ssh -q $MANAGER_HOST -- uname -a >$BASE_DIR/.kernel_version
