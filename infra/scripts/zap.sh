#!/bin/bash
# OWASP ZAP - DAST scan against the running application
# Usage: bash infra/scripts/zap.sh [--import-dojo]
# The app stack must be running: docker compose up -d

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"
DOJO_URL="${DOJO_URL:-http://localhost:8081}"
DOJO_TOKEN="${DOJO_TOKEN:-}"
DOJO_PRODUCT_NAME="${DOJO_PRODUCT_NAME:-BMI AppSec}"
DOJO_ENG_ZAP="${DOJO_ENG_ZAP:-}"
TARGET="${ZAP_TARGET:-http://localhost}"
IMPORT_DOJO="${1:-}"

mkdir -p "$REPORTS_DIR"

echo "========================================"
echo " OWASP ZAP - DAST"
echo "========================================"
echo " Target: $TARGET"
echo ""

# ZAP needs write permission on the wrk directory
chmod 777 "$REPORTS_DIR"

docker run --rm \
  --network host \
  -v "$REPORTS_DIR:/zap/wrk" \
  -v "$ROOT_DIR/infra/zap:/zap/config:ro" \
  zaproxy/zap-stable:latest \
  zap-full-scan.py \
  -t "$TARGET" \
  -J zap-report.json \
  -r zap-report.html \
  -x zap-report.xml \
  -c /zap/config/zap-rules.tsv \
  -I

REPORT_JSON="$REPORTS_DIR/zap-report.json"
REPORT_XML="$REPORTS_DIR/zap-report.xml"

ALERTS=$(python3 -c "
import json
data = json.load(open('$REPORT_JSON'))
sites = data.get('site', [])
total = sum(len(s.get('alerts', [])) for s in sites)
print(total)
" 2>/dev/null || echo "?")

echo ""
echo "✔ Report JSON: $REPORT_JSON"
echo "✔ Report XML:  $REPORT_XML"
echo "✔ Report HTML: $REPORTS_DIR/zap-report.html"
echo "✔ Alert types found: $ALERTS"

if [[ "$IMPORT_DOJO" == "--import-dojo" && -n "$DOJO_TOKEN" ]]; then
  echo ""
  echo "→ Importing to DefectDojo..."
  curl -s -X POST "$DOJO_URL/api/v2/import-scan/" \
    -H "Authorization: Token $DOJO_TOKEN" \
    -F "scan_type=ZAP Scan" \
    -F "engagement=$DOJO_ENG_ZAP" \
    -F "file=@$REPORT_XML" \
    -F "active=true" \
    -F "verified=false" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✔ Imported, test id:', d.get('test'))" 2>/dev/null || echo "✗ Import failed"
fi

echo ""
echo "✔ ZAP scan complete."
