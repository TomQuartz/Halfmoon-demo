#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway dynamodb-local
kubectl delete daemonsets boki-engine nop singleop
kubectl delete configmap env-config
kubectl delete service dynamodb-service zookeeper-service
