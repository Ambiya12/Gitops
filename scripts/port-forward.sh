#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Harbor UI    -> http://localhost:8081"
kubectl -n harbor port-forward svc/harbor-portal 8081:80 &

echo "[INFO] SonarQube   -> http://localhost:9000"
kubectl -n sonarqube port-forward svc/sonarqube-sonarqube 9000:9000 &

echo "[INFO] Argo CD UI  -> http://localhost:8080"
kubectl -n argocd port-forward svc/argocd-server 8080:80 &

wait
