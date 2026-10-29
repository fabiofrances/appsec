#!/bin/bash
# Trivy - Container image vulnerability scan
# Usage: bash infra/scripts/trivy.sh [--import-dojo]

set -euo pipefail

REPORTS_DIR="$(cd "$(dirname "$0")/../../reports" && pwd)"
HTML_TPL="$(cd "$(dirname "$0")/../trivy" && pwd)/html.tpl"
DOJO_URL="${DOJO_URL:-http://localhost:8081}"
DOJO_TOKEN="${DOJO_TOKEN:-}"
DOJO_PRODUCT_NAME="${DOJO_PRODUCT_NAME:-BMI AppSec}"
DOJO_ENG_TRIVY="${DOJO_ENG_TRIVY:-}"
IMPORT_DOJO="${1:-}"
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Sem binário nativo: roda a imagem oficial com o mesmo volume de cache dos labs
# (hands-on/scripts/trivy.sh), para o banco de vulnerabilidades ser baixado uma vez só.
# TRIVY_SKIP_DB_UPDATE=true usa o banco já em cache, sem ir à internet.
if ! command -v trivy >/dev/null 2>&1; then
  trivy() {
    docker run --rm \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v trivy-cache:/root/.cache/trivy \
      -v "$ROOT_DIR:$ROOT_DIR" -w "$ROOT_DIR" \
      -e TRIVY_SKIP_DB_UPDATE -e TRIVY_SKIP_JAVA_DB_UPDATE -e TRIVY_DB_REPOSITORY \
      "${TRIVY_IMAGE:-aquasec/trivy:0.58.1}" "$@"
  }
fi

mkdir -p "$REPORTS_DIR"

echo "========================================"
echo " Trivy - Container Scan"
echo "========================================"

for SERVICE in backend frontend; do
  IMAGE="appsec-bmi-${SERVICE}:latest"
  REPORT="$REPORTS_DIR/trivy-${SERVICE}.json"
  REPORT_HTML="$REPORTS_DIR/trivy-${SERVICE}.html"

  echo ""
  echo "▶ Scanning image: $IMAGE"

  trivy image \
    --format json \
    --output "$REPORT" \
    --severity CRITICAL,HIGH,MEDIUM \
    "$IMAGE"

  trivy image \
    --format template \
    --template "@$HTML_TPL" \
    --output "$REPORT_HTML" \
    --severity CRITICAL,HIGH,MEDIUM \
    "$IMAGE"

  VULNS=$(python3 -c "
import json, sys
data = json.load(open('$REPORT'))
total = sum(len(r.get('Vulnerabilities') or []) for r in data.get('Results', []))
print(total)
" 2>/dev/null || echo "?")

  echo "   ✔ JSON: $REPORT"
  echo "   ✔ HTML: $REPORT_HTML"
  echo "   ✔ Vulnerabilities found: $VULNS"

  if [[ "$IMPORT_DOJO" == "--import-dojo" && -n "$DOJO_TOKEN" ]]; then
    echo "   → Importing to DefectDojo..."
    curl -s -X POST "$DOJO_URL/api/v2/import-scan/" \
      -H "Authorization: Token $DOJO_TOKEN" \
      -F "scan_type=Trivy Scan" \
      -F "engagement=$DOJO_ENG_TRIVY" \
      -F "file=@$REPORT" \
      -F "active=true" \
      -F "verified=false" | python3 -c "import json,sys; d=json.load(sys.stdin); print('   ✔ Imported, test id:', d.get('test'))" 2>/dev/null || echo "   ✗ Import failed"
  fi
done

echo ""
echo "✔ Trivy scan complete. Reports in: $REPORTS_DIR"
