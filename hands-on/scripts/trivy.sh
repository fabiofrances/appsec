#!/bin/bash
# Wrapper do Trivy para os labs: usa o binário nativo se existir,
# senão roda a imagem oficial (necessário no Play with Docker).
# Usage: bash hands-on/scripts/trivy.sh <args do trivy>
# Rode a partir da raiz do repo: caminhos relativos são montados em /work.

set -euo pipefail

TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.58.1}"

if command -v trivy >/dev/null 2>&1; then
  exec trivy "$@"
fi

export MSYS_NO_PATHCONV=1   # Git Bash no Windows: não converter /work
exec docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache/trivy \
  -v "$PWD:/work" -w /work \
  "$TRIVY_IMAGE" "$@"
