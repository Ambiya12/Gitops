# Generic GitOps Pipeline (Local, Reusable)

This repository is a reusable GitOps foundation for local development on Apple Silicon (M2) using:

- k3d (K3s in Docker Desktop)
- Harbor (local container registry)
- SonarQube (code analysis)
- Argo CD (GitOps CD)
- GitHub Actions (CI with self-hosted runner)

## Repository Layout

- `app/`: application source, Dockerfile, and SonarQube config
- `deploy/`: Helm chart and Argo CD manifests
- `infra/`: k3d/bootstrap scripts and platform Helm values
- `.github/workflows/`: CI and promotion pipelines
- `scripts/`: helper automation scripts

## Quick Start (high-level)

1. Bootstrap local platform components from `infra/`
2. Build and push app image to Harbor from CI
3. Update Helm values image tag (GitOps bridge)
4. Let Argo CD auto-sync from `deploy/`

Implementation is committed in clean feature-by-feature steps.
