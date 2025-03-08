#!/bin/bash

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/..`

cd $ROOT_DIR/cmd
go build -o $ROOT_DIR/bin/demo .

if [ "$1" == "metric" ]; then
    cd $ROOT_DIR/metrics
    docker build -t shengqipku/hm-log-metrics .
    docker push shengqipku/hm-log-metrics
fi
