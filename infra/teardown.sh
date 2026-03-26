#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="gitops-lab"

echo "[INFO] Deleting k3d cluster '$CLUSTER_NAME'..."
k3d cluster delete "$CLUSTER_NAME"

echo "[DONE] Cluster deleted."
