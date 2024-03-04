#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

RUN=$1

QPS=(15)
LOGMODE=("read" "write")

for qps in ${QPS[@]}; do
    for mode in ${LOGMODE[@]}; do
        EXP_DIR=QPS${qps}_$mode
        if ! [ -d "$BASE_DIR/results/${EXP_DIR}_$RUN" ]; then
            $BASE_DIR/run_cloudlab.sh $EXP_DIR $qps $mode # 2>&1 | tee $BASE_DIR/run.log 
            mv $BASE_DIR/results/$EXP_DIR $BASE_DIR/results/${EXP_DIR}_$RUN
            $BASE_DIR/cleanup.sh
        fi
        echo "finished $BASE_DIR/$EXP_DIR"
        sleep 30
    done
done
