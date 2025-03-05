#!/bin/bash

BASE_DIR=`realpath $(dirname $0)`
cd $BASE_DIR

kubectl delete pods zookeeper zookeeper-setup boki-gateway boki-controller
kubectl delete daemonsets boki-engine boki-sequencer boki-storage
kubectl delete service zookeeper-service

kubectl delete -f ./k8s_files/db.yaml
kubectl delete -f ./k8s_files/metrics.yaml