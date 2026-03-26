#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="gitops-lab"
K3D_CONFIG="infra/k3d-config.yaml"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: $1"
    exit 1
  fi
}

for cmd in k3d kubectl helm; do
  require_cmd "$cmd"
done

echo "[INFO] Creating k3d cluster (if needed)..."
if ! k3d cluster list | awk '{print $1}' | grep -qx "$CLUSTER_NAME"; then
  k3d cluster create --config "$K3D_CONFIG"
else
  echo "[INFO] Cluster '$CLUSTER_NAME' already exists; skipping create."
fi

echo "[INFO] Creating namespaces..."
for ns in harbor sonarqube argocd dev staging prod ingress-nginx cert-manager; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns"
done

echo "[INFO] Adding Helm repositories..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo add jetstack https://charts.jetstack.io >/dev/null
helm repo add harbor https://helm.goharbor.io >/dev/null
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube >/dev/null
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

echo "[INFO] Installing ingress-nginx..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

echo "[INFO] Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true

echo "[INFO] Installing Harbor..."
helm upgrade --install harbor harbor/harbor \
  --namespace harbor \
  -f infra/harbor/values.yaml

echo "[INFO] Installing SonarQube..."
helm upgrade --install sonarqube sonarqube/sonarqube \
  --namespace sonarqube \
  -f infra/sonarqube/values.yaml

echo "[INFO] Installing Argo CD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f infra/argocd/values.yaml

echo "[INFO] Waiting for key deployments..."
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s
kubectl -n harbor rollout status deploy/harbor-core --timeout=300s || true
kubectl -n sonarqube rollout status statefulset/sonarqube-sonarqube --timeout=600s || true
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s || true

echo "[DONE] Platform bootstrap completed."
echo "[INFO] Endpoints (via localhost):"
echo "  Harbor:    http://harbor.localhost:30080"
echo "  SonarQube: http://sonar.localhost:30080"
echo "  Argo CD:   http://argocd.localhost:30080"
