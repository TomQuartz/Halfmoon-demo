#!/bin/bash

# Define the label selector
LABEL_SELECTOR="node-restriction.kubernetes.io/placement_label=storage_node"

# Get the node name(s) with the specified label
NODES=$(kubectl get nodes -l $LABEL_SELECTOR -o jsonpath='{.items[*].metadata.name}')

# Initialize variables to store total memory and node count
TOTAL_MEMORY_BYTES=0
NODE_COUNT=0

# Loop through each node and retrieve its memory usage
for NODE in $NODES; do
  # Get the MEMORY(Mi) using kubectl top node and awk to extract the value
  MEMORY_MI=$(kubectl top node $NODE --no-headers | awk '{print $3}' | sed 's/Mi//')

  MEMORY_BYTES=$(echo "$MEMORY_MI * 1024 * 1024" | bc)

  # Add the current node's memory to the total memory
  TOTAL_MEMORY_BYTES=$((TOTAL_MEMORY_BYTES + MEMORY_BYTES))

  # Increment the node count
  NODE_COUNT=$((NODE_COUNT + 1))
done

# Calculate the average memory usage in bytes
if [ $NODE_COUNT -gt 0 ]; then
  AVERAGE_MEMORY_BYTES=$((TOTAL_MEMORY_BYTES / NODE_COUNT))
else
  echo "No Halfmoon log storage nodes found."
fi

LOG_METRIC_SERVER="http://localhost:30180"
EXTRA_MEMORY_BYTES=$(curl -s $LOG_METRIC_SERVER/value)
AVERAGE_MEMORY_BYTES=$((AVERAGE_MEMORY_BYTES + EXTRA_MEMORY_BYTES))

echo "Log memory usage: $AVERAGE_MEMORY_BYTES bytes"
