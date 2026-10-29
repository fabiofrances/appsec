#!/bin/bash
# Compara imagens: tamanho, nº de camadas, usuário e CVEs (Trivy) em tabela Markdown.
# Usage: bash hands-on/scripts/compare.sh [imagem ...]
# Sem argumentos: todas as tags locais de handson/backend e handson/api-go.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="reports/compare"
mkdir -p "$OUT_DIR"

if [[ $# -gt 0 ]]; then
  IMAGES=("$@")
else
  mapfile -t IMAGES < <(
    for REPO in handson/backend handson/api-go; do
      docker images "$REPO" --format '{{.Repository}}:{{.Tag}}'
    done | sort
  )
fi

if [[ ${#IMAGES[@]} -eq 0 ]]; then
  echo "Nenhuma imagem handson/* encontrada. Rode: make lab-single lab-multi lab-bases lab-go"
  exit 1
fi

# conta pelo JSON do trivy sem depender de python/jq (portável para o PWD)
count() { grep -c "\"Severity\": \"$1\"" "$2" || true; }   # grep -c sai com 1 quando é 0

ROWS=()
for IMAGE in "${IMAGES[@]}"; do
  echo "▶ $IMAGE" >&2
  BYTES=$(docker image inspect -f '{{.Size}}' "$IMAGE")
  SIZE_MB=$(( BYTES / 1024 / 1024 ))
  LAYERS=$(docker image inspect -f '{{len .RootFS.Layers}}' "$IMAGE")
  USER_=$(docker image inspect -f '{{.Config.User}}' "$IMAGE")
  REPORT="$OUT_DIR/$(echo "$IMAGE" | tr '/:' '__').json"

  bash "$SCRIPT_DIR/trivy.sh" image --quiet --scanners vuln \
    --severity CRITICAL,HIGH,MEDIUM --format json --output "$REPORT" "$IMAGE"

  ROWS+=("| \`$IMAGE\` | ${SIZE_MB} MB | $LAYERS | ${USER_:-root} | $(count CRITICAL "$REPORT") | $(count HIGH "$REPORT") | $(count MEDIUM "$REPORT") |")
done

echo ""
echo "| Imagem | Tamanho | Camadas | Usuário | CRITICAL | HIGH | MEDIUM |"
echo "|---|---|---|---|---|---|---|"
printf '%s\n' "${ROWS[@]}"
