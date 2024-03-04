#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway
kubectl delete daemonsets boki-engine login profile timeline post publish
kubectl delete configmap env-config
kubectl delete service zookeeper-service
