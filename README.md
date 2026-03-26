# Generic GitOps Pipeline (Local, Reusable)

This repository provides a reusable GitOps foundation for local ARM64 development environments.

Stack:

- k3d (K3s in Docker Desktop)
- Harbor (local image registry)
- SonarQube (code quality)
- Argo CD (GitOps CD)
- GitHub Actions (CI via self-hosted runner)

## Repository Layout

- `app/`: Node.js/TypeScript sample app + Dockerfile
- `deploy/`: Helm chart + Argo CD manifests
- `infra/`: k3d config, bootstrap/teardown, and platform Helm values
- `.github/workflows/`: CI and promotion workflows
- `scripts/`: helper scripts (image tag update and local port-forward)

## Prerequisites

Install the following tools on macOS:

- Docker Desktop
- `kubectl`
- `helm`
- `k3d`
- `argocd` CLI (optional but recommended)
- `yq` (optional for local manifest edits)

## Resource Tuning (16 GB RAM)

Recommended Docker Desktop settings:

- Memory: `10 GB`
- CPUs: `6`
- Swap: `2 GB`

This repository already applies conservative per-service limits in:

- `infra/harbor/values.yaml`
- `infra/sonarqube/values.yaml`
- `infra/argocd/values.yaml`

## Step-by-Step Setup

### 1. Bootstrap local cluster and platform services

```bash
./infra/bootstrap.sh
```

This installs NGINX Ingress, cert-manager, Harbor, SonarQube, and Argo CD into k3d.

### 2. Verify cluster and services

```bash
kubectl get nodes
kubectl get pods -A
```

Optional quick UI access via port-forward:

```bash
./scripts/port-forward.sh
```

### 3. Register a self-hosted GitHub Actions runner

Create a runner token from:

- GitHub repo -> `Settings` -> `Actions` -> `Runners` -> `New self-hosted runner`

Run:

```bash
./infra/actions-runner/setup-runner.sh https://github.com/Ambiya12/Gitops <RUNNER_TOKEN>
cd ~/actions-runner && ./run.sh
```

### 4. Configure GitHub repository secrets

Add these repo secrets:

- `HARBOR_USERNAME`
- `HARBOR_PASSWORD`
- `SONAR_TOKEN`

Workflow files:

- `.github/workflows/ci.yaml`
- `.github/workflows/promote.yaml`

### 5. Configure Argo CD to track this repo

Apply project and applicationset:

```bash
kubectl apply -n argocd -f deploy/argocd/project.yaml
kubectl apply -n argocd -f deploy/argocd/applicationset.yaml
```

The `ApplicationSet` creates 3 apps:

- `gitops-app-dev` (auto-sync + self-heal)
- `gitops-app-staging` (auto-sync + self-heal)
- `gitops-app-prod` (manual sync for safety)

### 6. Trigger CI and GitOps flow

Push to `main`:

1. CI builds/tests app
2. SonarQube scan runs
3. Docker image is built for `linux/arm64` and pushed to Harbor
4. CI updates `deploy/chart/values-dev.yaml` image tag
5. Argo CD detects manifest change and syncs `dev`

## Multi-Arch Build Notes

Current CI target is `linux/arm64` (optimized for local ARM64 runtime):

- see `.github/workflows/ci.yaml` -> `docker/build-push-action`

For hybrid local/cloud scenarios, extend to:

- `platforms: linux/arm64,linux/amd64`

## Promotion Flow

Use the `promote` workflow manually:

- `target_env`: `staging` or `prod`
- `image_tag`: commit SHA to promote

This updates the corresponding values file in `deploy/chart/` and pushes the change.

## Useful Commands

```bash
# Recreate cluster from scratch
./infra/teardown.sh && ./infra/bootstrap.sh

# Render Helm chart locally
helm template demo deploy/chart -f deploy/chart/values-dev.yaml

# Check Argo CD applications
kubectl get applications -n argocd
```

## Notes

- Harbor is configured with `trivy` disabled to reduce memory footprint on a 16 GB laptop.
- SonarQube JVM heap is tuned in `infra/sonarqube/values.yaml`.
- CI GitOps bridge commits include `[skip ci]` to avoid pipeline loops.
