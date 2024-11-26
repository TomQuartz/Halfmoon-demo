#!/bin/bash
set -u

BASE_DIR=`realpath $(dirname $0)`
ROOT_DIR=`realpath $BASE_DIR/..`

# setup aws credentials
mkdir -p ~/.aws
cp $ROOT_DIR/scripts/.aws/credentials ~/.aws/credentials

# create a pod for database
kubectl apply -f "$BASE_DIR/db.yaml"
sleep 40

cd $BASE_DIR/singleop
./run_quick_cloudlab.sh 1 2>&1 | tee run.log
echo "Finished singleop"

# cd $BASE_DIR/workflow
# ./run_quick_cloudlab.sh 1 2>&1 | tee run.log
# echo "Finished workflow"

# cd $BASE_DIR/overhead
# ./run_quick_cloudlab.sh 1 2>&1 | tee run.log
# echo "Finished overhead"

# cd $BASE_DIR/switching
# ./run_all_cloudlab.sh 1 2>&1 | tee run.log
# echo "Finished switching"

kubectl delete pod dynamodb-local
kubectl delete service dynamodb-service
