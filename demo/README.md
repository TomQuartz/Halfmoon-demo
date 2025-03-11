Halfmoon demo
==================================

### Deploying Halfmoon demo

**requirements**
- A running Kubernetes cluster with a minimum of 10 nodes
  - nodes should ssh-able. The ssh hostnames should match the Kubernetes node names
  - tested on Ubuntu 22.04 Kubernetes v1.30.0

```shell
# replace the node names with that in your actual cluster
ENGINES=worker1 SEQUENCERS=worker2 STORAGES=worker3 GATEWAY=worker4 \
    ./scripts/deploy.sh
```

NOTE: this step takes ~3 minutes

### Running demo app

```shell
./scripts/run.sh
```

### Halfmoon Log Storage Memory Usage

```shell
# outputs the current usage
./scripts/metric.sh
```

### Cleaning up Halfmoon

```shell
./scripts/cleanup.sh
```