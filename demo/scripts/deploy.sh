#!/bin/bash

set -x

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/..`
cd $ROOT_DIR

IFS=',' read -r -a ENGINE_HOSTS <<< "$ENGINES"
IFS=',' read -r -a SEQUENCER_HOSTS <<< "$SEQUENCERS"
IFS=',' read -r -a STORAGE_HOSTS <<< "$STORAGES"

MANAGER_HOST=$GATEWAY

ALL_HOSTS=("${ENGINE_HOSTS[@]}" "${SEQUENCER_HOSTS[@]}" "${STORAGE_HOSTS[@]}" $MANAGER_HOST)

# setup aws credentials
mkdir -p ~/.aws
cp ./credentials ~/.aws/credentials

# create a pod for database
kubectl apply -f "./k8s_files/db.yaml"
kubectl apply -f "./k8s_files/metrics.yaml"
sleep 40

TABLE_PREFIX=$(head -c 64 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
TABLE_PREFIX="${TABLE_PREFIX}-"

# assign labels and copy scripts to the corresponding nodes
engine_id=0
for HOST in ${ENGINE_HOSTS[@]}; do 
    engine_id=$((engine_id+1))
    echo engine$engine_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=engine_node --overwrite
    scp -q ./k8s_files/engine_start.sh $HOST:/tmp/engine_start.sh
    ssh -q $HOST -- sudo rm -rf /mnt/inmem/.aws ~/.aws
    ssh -q $HOST -- mkdir -p ~/.aws
    scp -q ./credentials $HOST:~/.aws
    ssh -q $HOST -- sudo cp -r ~/.aws /mnt/inmem/
done
sequencer_id=0
for HOST in ${SEQUENCER_HOSTS[@]}; do 
    sequencer_id=$((sequencer_id+1))
    echo sequencer$sequencer_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=sequencer_node --overwrite
    scp -q ./k8s_files/sequencer_start.sh $HOST:/tmp/sequencer_start.sh
done
storage_id=0
for HOST in ${STORAGE_HOSTS[@]}; do 
    storage_id=$((storage_id+1))
    echo storage$storage_id | ssh -q $HOST -- sudo tee /tmp/node_name
    kubectl label nodes $HOST node-restriction.kubernetes.io/placement_label=storage_node --overwrite
    scp -q ./k8s_files/storage_start.sh $HOST:/tmp/storage_start.sh
done
kubectl label nodes $MANAGER_HOST node-restriction.kubernetes.io/placement_label=gateway_node --overwrite

scp -q ./zk_setup.sh $MANAGER_HOST:/tmp/
ssh -q $MANAGER_HOST -- sudo mkdir -p /mnt/inmem/store

for HOST in ${ALL_HOSTS[@]}; do
    scp -q ./nightcore_config.json $HOST:/tmp/nightcore_config.json
done

for HOST in ${ENGINE_HOSTS[@]}; do
    # scp -q ./run_launcher $HOST:/tmp/run_launcher
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
kubectl apply -f "./k8s_files/zookeeper.yaml"
sleep 10
# set up zookeeper
kubectl apply -f "./k8s_files/zookeeper-setup.yaml"
sleep 30
kubectl apply -f "./k8s_files/boki-engine.yaml"
kubectl apply -f "./k8s_files/boki-gateway.yaml"
kubectl apply -f "./k8s_files/boki-storage.yaml"
kubectl apply -f "./k8s_files/boki-sequencer.yaml"
sleep 30
kubectl apply -f "./k8s_files/boki-controller.yaml"

# deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.1/components.yaml
kubectl patch -n kube-system deployment metrics-server \
    --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args/2", "value": "--kubelet-preferred-address-types=InternalIP"},
        {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

sleep 40
