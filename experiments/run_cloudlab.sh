#!/bin/bash
set -u

BASE_DIR=`realpath $(dirname $0)`

# create a pod for database
kubectl apply -f "$BASE_DIR/k8s_files/db.yaml"
sleep 40

cd $BASE_DIR/singleop
./run_quick_cloudlab.sh 1 >run.log 2>&1
echo "Finished singleop"

cd $BASE_DIR/workflow
./run_quick_cloudlab.sh 1 >run.log 2>&1
echo "Finished workflow"

cd $BASE_DIR/overhead
./run_quick_cloudlab.sh 1 >run.log 2>&1
echo "Finished overhead"

cd $BASE_DIR/switching
./run_all_cloudlab.sh 1 >run.log 2>&1
echo "Finished switching"

kubectl delete pod dynamodb-local
kubectl delete service dynamodb-service
