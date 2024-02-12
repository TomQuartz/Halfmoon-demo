#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway
kubectl delete daemonsets boki-engine nop singleop
