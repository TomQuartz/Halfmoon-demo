#!/bin/bash

kubectl delete pods zookeeper zookeeper-setup boki-gateway boki-controller
kubectl delete daemonsets boki-engine boki-sequencer boki-storage frontend cast-info review-storage user-review \
    movie-review compose-review text user unique-id rating movie-id plot movie-info page
kubectl delete service zookeeper-service
kubectl delete configmap env-config
