#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway boki-controller
kubectl delete daemonsets boki-engine boki-sequencer boki-storage login profile timeline post publish
kubectl delete service zookeeper-service
kubectl delete configmap env-config
