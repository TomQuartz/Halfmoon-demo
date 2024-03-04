#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/../..`

RUN=$1

CONCURRENCY=(16 40)
ops=10 # NUM_OPS
rr="0.2,0.8" # READ_RATIO

for cc in ${CONCURRENCY[@]}; do
    EXP_DIR=con${cc}_n${ops}_rr${rr}
    if [ -d "$BASE_DIR/results/${EXP_DIR}_$RUN" ]; then
        echo "finished $BASE_DIR/$EXP_DIR"
        continue
    fi
    sleep 60
    $BASE_DIR/run_cloudlab.sh $EXP_DIR $cc $ops $rr # 2>&1 | tee $BASE_DIR/run.log 
    mv $BASE_DIR/results/$EXP_DIR $BASE_DIR/results/${EXP_DIR}_$RUN
    $BASE_DIR/cleanup.sh
    echo "finished $BASE_DIR/$EXP_DIR"
done

$BASE_DIR/plot_switching.py --concurrency ${CONCURRENCY[@]} --nops $ops --read-ratios $rr $RUN