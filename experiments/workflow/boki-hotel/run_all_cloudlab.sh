#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../../..`

RUN=$1

# QPS=(100 200 300 400 500 600 700 800 900 1000 1100)
# QPS=(100 300 500 700)
QPS=(100 200 300 400 500 600 700 800 900)

for qps in ${QPS[@]}; do
    EXP_DIR=QPS$qps
    if [ -d "$BASE_DIR/results/${EXP_DIR}_$RUN" ]; then
        echo "finished $BASE_DIR/$EXP_DIR"
        continue
    fi

    MAX_RETRIES=3
    while [ $MAX_RETRIES -gt 0 ]; do
        sleep 60
        ((MAX_RETRIES--))
        $BASE_DIR/run_cloudlab.sh $EXP_DIR $qps # 2>&1 | tee run.log 
        if [ -s "$BASE_DIR/results/$EXP_DIR/async_results" ]; then
            mv $BASE_DIR/results/$EXP_DIR $BASE_DIR/results/${EXP_DIR}_$RUN
            $BASE_DIR/cleanup.sh
            echo "finished $BASE_DIR/$EXP_DIR"
            break
        else
            echo "retrying $BASE_DIR/$EXP_DIR"
            rm -rf $BASE_DIR/results/$EXP_DIR
            $BASE_DIR/cleanup.sh
        fi
    done
done
