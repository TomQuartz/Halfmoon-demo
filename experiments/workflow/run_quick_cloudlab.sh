#!/bin/bash
BASE_DIR=`realpath $(dirname $0)`

RUN=$1

cd $BASE_DIR
./opt-hotel/run_all_cloudlab.sh $RUN
sleep 10
./boki-hotel/run_all_cloudlab.sh $RUN
sleep 10
./baseline-hotel/run_all_cloudlab.sh $RUN
sleep 10
./opt-movie/run_all_cloudlab.sh $RUN
sleep 10
./boki-movie/run_all_cloudlab.sh $RUN
sleep 10
./baseline-movie/run_all_cloudlab.sh $RUN
sleep 10
./opt-retwis/run_all_cloudlab.sh $RUN
sleep 10
./boki-retwis/run_all_cloudlab.sh $RUN
sleep 10
./baseline-retwis/run_all_cloudlab.sh $RUN

./plot_workflow.py --qps 100 200 300 400 500 600 700 800 900 -- hotel $RUN
./plot_workflow.py --qps 50 100 150 200 250 300 350 400 450 -- movie $RUN
./plot_workflow.py --qps 100 200 300 400 500 600 700 800 900 -- retwis $RUN