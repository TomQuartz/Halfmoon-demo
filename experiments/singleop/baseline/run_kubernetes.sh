#!/bin/bash

set -u

BASE_DIR=`realpath .`
ROOT_DIR=`realpath $BASE_DIR/../../..`

minikube start --force

# move local zk_setup.sh to minikube node
minikube cp $ROOT_DIR/scripts/zk_setup.sh minikube:/tmp/zk_setup.sh
# change execution permission bit
minikube ssh -- sudo chmod +x /tmp/zk_setup.sh
minikube ssh -- sudo mkdir -p /mnt/inmem/store

# to all hosts
minikube cp $BASE_DIR/nightcore_config.json minikube:/tmp/nightcore_config.json
# to engine hosts
minikube cp $BASE_DIR/run_launcher minikube:/tmp/run_launcher
minikube ssh -- sudo chmod +x /tmp/run_launcher
minikube ssh -- sudo rm -rf /mnt/inmem/boki
minikube ssh -- sudo mkdir -p /mnt/inmem/boki
minikube ssh -- sudo mkdir -p /mnt/inmem/boki/output /mnt/inmem/boki/ipc
minikube ssh -- sudo cp /tmp/run_launcher /mnt/inmem/boki/run_launcher
minikube ssh -- sudo cp /tmp/nightcore_config.json /mnt/inmem/boki/func_config.json
# to storage hosts
minikube ssh -- sudo rm -rf   /mnt/storage/logdata
minikube ssh -- sudo mkdir -p /mnt/storage/logdata

sleep 10

# start zookeeper
kubectl apply -f "$BASE_DIR/k8s_files/zookeeper.yaml"
sleep 10
# set up zookeeper
kubectl apply -f "$BASE_DIR/k8s_files/zookeeper-setup.yaml"
sleep 10
# kubectl exec -it zookeeper-setup -- bash /tmp/boki/zk_setup.sh
# sleep 120