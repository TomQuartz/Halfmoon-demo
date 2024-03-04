#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway
kubectl delete daemonsets boki-engine frontend cast-info review-storage user-review \
    movie-review compose-review text user unique-id rating movie-id plot movie-info page
kubectl delete configmap env-config
kubectl delete service zookeeper-service
