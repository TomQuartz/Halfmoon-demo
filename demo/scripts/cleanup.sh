#!/bin/bash

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/..`
cd $ROOT_DIR

kubectl delete pods zookeeper zookeeper-setup boki-gateway boki-controller
kubectl delete daemonsets boki-engine boki-sequencer boki-storage
kubectl delete service zookeeper-service

kubectl delete -f ./k8s_files/db.yaml
kubectl delete -f ./k8s_files/metrics.yaml

kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.1/components.yaml
