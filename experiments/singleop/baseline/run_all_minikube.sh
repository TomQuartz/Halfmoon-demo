#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

RUN=$1

QPS=(15)

minikube start --force

for qps in ${QPS[@]}; do
    EXP_DIR=QPS$qps
    if ! [ -d "$BASE_DIR/results/${EXP_DIR}_$RUN" ]; then
        $BASE_DIR/run_minikube.sh $EXP_DIR $qps # 2>&1 | tee $BASE_DIR/run.log 
        mv $BASE_DIR/results/$EXP_DIR $BASE_DIR/results/${EXP_DIR}_$RUN
    fi
    echo "finished $BASE_DIR/$EXP_DIR"
done

minikube delete
