#!/bin/bash
# Duelo de imagens base: Alpine x Distroless (x Chainguard...) com a MESMA app.
# Mede o que importa para o debate: tamanho, superfície (arquivos, shell, gerenciador
# de pacotes, libc), CVEs, tempo até responder e memória em uso.
# Usage: bash hands-on/scripts/duel.sh [imagem ...]
# Padrão: handson/backend:alpine handson/backend:distroless

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="reports/duel"
mkdir -p "$OUT_DIR"

if [[ $# -gt 0 ]]; then
  IMAGES=("$@")
else
  IMAGES=(handson/backend:alpine handson/backend:distroless)
fi

count() { grep -o "\"Severity\": \"$1\"" "$2" | wc -l | tr -d ' '; }
has() { grep -qE "$1" "$2" && echo "sim" || echo "não"; }

declare -A R
PORT=3100
for IMAGE in "${IMAGES[@]}"; do
  PORT=$((PORT + 1))
  NAME="duel-$PORT"
  SLUG=$(echo "$IMAGE" | tr '/:' '__')
  echo "▶ $IMAGE" >&2

  # ── superfície: lista o filesystem sem precisar de shell na imagem ──────────
  FILES="$OUT_DIR/$SLUG.files"
  CID=$(docker create "$IMAGE")
  docker export "$CID" | tar -t > "$FILES"
  docker rm "$CID" >/dev/null

  R[$IMAGE,size]="$(( $(docker image inspect -f '{{.Size}}' "$IMAGE") / 1024 / 1024 )) MB"
  R[$IMAGE,files]=$(grep -vc '/$' "$FILES")
  R[$IMAGE,bins]=$(grep -cE '^(usr/)?s?bin/[^/]+$' "$FILES" || true)
  R[$IMAGE,shell]=$(has '^bin/(sh|bash|ash)$' "$FILES")
  R[$IMAGE,pkg]=$(has '^(sbin/apk|usr/bin/apt-get|usr/bin/dpkg|usr/bin/apk)$' "$FILES")
  if grep -qE '^lib/ld-musl' "$FILES"; then R[$IMAGE,libc]="musl"
  elif grep -qE 'libc\.so\.6$' "$FILES"; then R[$IMAGE,libc]="glibc"
  else R[$IMAGE,libc]="nenhuma"; fi
  R[$IMAGE,busybox]=$(has '^bin/busybox$' "$FILES")
  USER_=$(docker image inspect -f '{{.Config.User}}' "$IMAGE")
  R[$IMAGE,user]="${USER_:-root}"

  # ── CVEs ────────────────────────────────────────────────────────────────────
  REPORT="$OUT_DIR/$SLUG.json"
  bash "$SCRIPT_DIR/trivy.sh" image --quiet --scanners vuln \
    --severity CRITICAL,HIGH,MEDIUM,LOW --format json --output "$REPORT" "$IMAGE"
  R[$IMAGE,cve]="$(count CRITICAL "$REPORT") / $(count HIGH "$REPORT") / $(count MEDIUM "$REPORT") / $(count LOW "$REPORT")"

  # ── runtime: tempo até o /health responder e memória em uso ─────────────────
  START=$(date +%s%N)
  docker run -d --rm --name "$NAME" -p "$PORT:3000" -e OTEL_SDK_DISABLED=true "$IMAGE" >/dev/null
  READY="timeout"
  for _ in $(seq 1 150); do
    if curl -sf "localhost:$PORT/health" >/dev/null 2>&1; then
      READY="$(( ($(date +%s%N) - START) / 1000000 )) ms"
      break
    fi
    sleep 0.2
  done
  R[$IMAGE,ready]="$READY"
  R[$IMAGE,mem]=$(docker stats --no-stream --format '{{.MemUsage}}' "$NAME" | cut -d/ -f1 | tr -d ' ')
  R[$IMAGE,exec]=$(docker exec "$NAME" sh -c true >/dev/null 2>&1 && echo "funciona" || echo "falha")
  docker stop "$NAME" >/dev/null
done

ROWS=(
  "size|Tamanho"
  "files|Arquivos no filesystem"
  "bins|Executáveis em /bin, /usr/bin..."
  "shell|Shell (/bin/sh)"
  "busybox|BusyBox"
  "pkg|Gerenciador de pacotes"
  "libc|libc"
  "user|Usuário padrão"
  "cve|CVEs C / H / M / L"
  "ready|Tempo até /health responder"
  "mem|Memória em uso"
  "exec|docker exec sh"
)

echo ""
printf '| Métrica |'; for I in "${IMAGES[@]}"; do printf ' `%s` |' "$I"; done; echo
printf '|---|'; for _ in "${IMAGES[@]}"; do printf -- '---|'; done; echo
for ROW in "${ROWS[@]}"; do
  KEY="${ROW%%|*}"; LABEL="${ROW#*|}"
  printf '| %s |' "$LABEL"
  for I in "${IMAGES[@]}"; do printf ' %s |' "${R[$I,$KEY]}"; done
  echo
done
