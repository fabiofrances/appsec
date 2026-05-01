#!/bin/bash
# OWASP Dependency Check - SCA scan on backend and frontend dependencies
# Usage: bash infra/scripts/dependency-check.sh [--import-dojo]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"
DOJO_URL="${DOJO_URL:-http://localhost:8081}"
DOJO_TOKEN="${DOJO_TOKEN:-}"
DOJO_PRODUCT_NAME="${DOJO_PRODUCT_NAME:-BMI AppSec}"
DOJO_ENG_DEPCHECK="${DOJO_ENG_DEPCHECK:-}"
IMPORT_DOJO="${1:-}"

mkdir -p "$REPORTS_DIR"

echo "========================================"
echo " OWASP Dependency Check - SCA"
echo "========================================"
echo ""

# Descomente abaixo para instalar node_modules automaticamente antes do scan
# echo "▶ Instalando dependências npm para scan completo..."
# for dir in backend frontend; do
#   if [[ ! -d "$ROOT_DIR/$dir/node_modules" ]]; then
#     echo "  → npm install em $dir..."
#     (cd "$ROOT_DIR/$dir" && npm install --prefer-offline --silent 2>/dev/null || npm install --silent)
#   fi
# done

EXTRA_ARGS=()
[[ -n "${NVD_API_KEY:-}" ]] && EXTRA_ARGS+=(--nvdApiKey "$NVD_API_KEY")
[[ "${SKIP_UPDATE:-}" == "1" ]] && EXTRA_ARGS+=(--noupdate)

docker run --rm \
  -v "$ROOT_DIR:/src:ro" \
  -v "$REPORTS_DIR:/reports" \
  -v odc-data:/usr/share/dependency-check/data \
  owasp/dependency-check:11.1.1 \
  --scan /src/backend \
  --scan /src/frontend \
  --project "bmi-appsec" \
  --format JSON \
  --format HTML \
  --format XML \
  --out /reports \
  "${EXTRA_ARGS[@]}" \
  --enableRetired

echo ""
REPORT="$REPORTS_DIR/dependency-check-report.json"

VULNS=$(python3 -c "
import json
data = json.load(open('$REPORT'))
deps = data.get('dependencies', [])
vuln_count = sum(len(d.get('vulnerabilities', [])) for d in deps)
print(vuln_count)
" 2>/dev/null || echo "?")

echo "✔ Report JSON: $REPORT"
echo "✔ Report XML:  $REPORTS_DIR/dependency-check-report.xml"
echo "✔ Report HTML: $REPORTS_DIR/dependency-check-report.html"
echo "✔ Vulnerabilities found: $VULNS"

if [[ "$IMPORT_DOJO" == "--import-dojo" && -n "$DOJO_TOKEN" ]]; then
  echo ""
  echo "→ Importing to DefectDojo..."
  curl -s -X POST "$DOJO_URL/api/v2/import-scan/" \
    -H "Authorization: Token $DOJO_TOKEN" \
    -F "scan_type=Dependency Check Scan" \
    -F "engagement=$DOJO_ENG_DEPCHECK" \
    -F "file=@$REPORTS_DIR/dependency-check-report.xml" \
    -F "active=true" \
    -F "verified=false" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✔ Imported, test id:', d.get('test'))" 2>/dev/null || echo "✗ Import failed"
fi

echo ""
echo "✔ Dependency Check complete."
