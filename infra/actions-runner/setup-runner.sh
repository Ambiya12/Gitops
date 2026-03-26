#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./infra/actions-runner/setup-runner.sh <repo-url> <registration-token> [runner-name]

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <repo-url> <registration-token> [runner-name]"
  echo "Example: $0 https://github.com/Ambiya12/Gitops ghp_runner_token gitops-arm64-runner"
  exit 1
fi

REPO_URL="$1"
RUNNER_TOKEN="$2"
RUNNER_NAME="${3:-gitops-arm64-runner}"
RUNNER_VERSION="2.327.1"
RUNNER_DIR="${HOME}/actions-runner"

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [[ ! -f ./config.sh ]]; then
  echo "[INFO] Downloading GitHub Actions runner ${RUNNER_VERSION}..."
  curl -fsSL -o actions-runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"
  tar xzf actions-runner.tar.gz
fi

echo "[INFO] Configuring runner '${RUNNER_NAME}'..."
./config.sh \
  --url "$REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "self-hosted,macos,arm64,gitops" \
  --work "_work" \
  --unattended \
  --replace

echo "[DONE] Runner configured."
echo "Start it with:"
echo "  cd ${RUNNER_DIR} && ./run.sh"
