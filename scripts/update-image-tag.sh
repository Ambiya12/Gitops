#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <values-file> <new-tag>"
  exit 1
fi

VALUES_FILE="$1"
NEW_TAG="$2"

if [[ ! -f "$VALUES_FILE" ]]; then
  echo "[ERROR] File not found: $VALUES_FILE"
  exit 1
fi

if command -v yq >/dev/null 2>&1; then
  yq -i ".image.tag = \"${NEW_TAG}\"" "$VALUES_FILE"
else
  # Fallback for environments where yq is unavailable.
  sed -i.bak -E "s|^(\s*tag:\s*).*$|\1\"${NEW_TAG}\"|" "$VALUES_FILE"
  rm -f "${VALUES_FILE}.bak"
fi

echo "[DONE] Updated ${VALUES_FILE} image.tag -> ${NEW_TAG}"
