#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway
kubectl delete daemonsets boki-engine geo profile rate recommendation user hotel search flight order frontend gateway
kubectl delete configmap env-config
kubectl delete service zookeeper-service
