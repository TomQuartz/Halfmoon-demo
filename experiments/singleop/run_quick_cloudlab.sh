#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`

RUN=$1

cd $BASE_DIR
./baseline/run_all_cloudlab.sh $RUN
./plot_singleop.py --qps 15 $RUN
sleep 10
./boki/run_all_cloudlab.sh $RUN
./plot_singleop.py --qps 15 $RUN
sleep 10
./optimal/run_all_cloudlab.sh $RUN
./plot_singleop.py --qps 15 $RUN

# ./plot_singleop.py --qps 15 $RUN