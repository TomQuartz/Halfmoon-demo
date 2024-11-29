Benchmark workloads of Halfmoon
==================================

This repository includes the artifacts of our SOSP '23 paper that are runnable on Kubernetes.

### Structure of this repository ###

* `dockerfiles`: Dockerfiles for building relevant Docker images.
* `workloads`: source code of Halfmoon client library and evalution workloads. 
* `experiments`: scripts for running individual experiments.
* `scripts`: helper scripts for setting up AWS EC2 environment, building Docker images, and summarizing experiment results.
* `halfmoon`: git submodule containing our implementation of [Halfmoon](https://github.com/pkusys/Halfmoon)'s logging layer, which is based on SOSP '21 paper [Boki](https://github.com/ut-osa/boki)

### Hardware and software dependencies ###

Halfmoon requires linux 5.10 or later to run.

### Environment setup ###

1. Setup a Kubernetes cluster using Kubeadm.
   - The nodes should ssh-able. The ssh hostnames should match the Kubernetes node names.
   - There should be at least 11 nodes in the cluster, including 1 master node and 10 worker nodes.
2. Update the hosts in `experiments/singleop/*/run_cloudlab.sh` with your node names. `*` can be `baseline`, `boki`, and `optimal`. Example:
```shell
ENGINE_HOSTS=("node7" "node8" "node9")
SEQUENCER_HOSTS=("node1" "node2" "node3")
STORAGE_HOSTS=("node4" "node5" "node6")
MANAGER_HOST="node10"
CLIENT_HOST="master1"
ENTRY_HOST="node10"
```
**NOTE:** the hosts should not overlap, except that `MANAGER_HOST` and `ENTRY_HOST` are the same.

2. On the master node, run `experiments/run_cloudlab.sh`
3. The visualized results can be found at `experiments/singleop/figures`
   - The plotting script requires the following python packages `parse numpy matplotlib`

### Limitations

Currently, we only port the microbenchmarks (i.e., the `singleop` experiment) to Kubernetes.

### License ###

* The logging layer of [Halfmoon](https://github.com/pkusys/Halfmoon) is based on based on [Boki](https://github.com/ut-osa/boki). Halfmoon is licensed under Apache License 2.0, in accordance with Boki.
* The Halfmoon client library and evaluation workloads (`workloads/workflow`) are based on [Beldi codebase](https://github.com/eniac/Beldi) and [BokiFlow](https://github.com/ut-osa/boki-benchmarks). Both are licensed under MIT License, and so is our source code.
* All other source code in this repository is licensed under Apache License 2.0.