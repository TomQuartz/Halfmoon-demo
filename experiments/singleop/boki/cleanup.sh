#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway boki-controller dynamodb-local
kubectl delete daemonsets boki-engine boki-sequencer boki-storage nop singleop
kubectl delete service dynamodb-service zookeeper-service
kubectl delete configmap env-config
