#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway
kubectl delete daemonsets boki-engine nop singleop
kubectl delete configmap env-config
kubectl delete service zookeeper-service
