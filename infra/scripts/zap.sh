#!/bin/bash
# OWASP ZAP - DAST scan against the running application
# Usage: bash infra/scripts/zap.sh [--import-dojo]
# The app stack must be running: docker compose up -d

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"
DOJO_URL="${DOJO_URL:-http://localhost:8081}"
DOJO_TOKEN="${DOJO_TOKEN:-}"
DOJO_PRODUCT_ID="${DOJO_PRODUCT_ID:-}"
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
  -c /zap/config/zap-rules.tsv \
  -I

REPORT="$REPORTS_DIR/zap-report.json"

ALERTS=$(python3 -c "
import json
data = json.load(open('$REPORT'))
sites = data.get('site', [])
total = sum(len(s.get('alerts', [])) for s in sites)
print(total)
" 2>/dev/null || echo "?")

echo ""
echo "✔ Report JSON: $REPORT"
echo "✔ Report HTML: $REPORTS_DIR/zap-report.html"
echo "✔ Alert types found: $ALERTS"

if [[ "$IMPORT_DOJO" == "--import-dojo" && -n "$DOJO_TOKEN" ]]; then
  echo ""
  echo "→ Importing to DefectDojo..."
  curl -s -X POST "$DOJO_URL/api/v2/import-scan/" \
    -H "Authorization: Token $DOJO_TOKEN" \
    -F "scan_type=ZAP Scan" \
    -F "product_id=$DOJO_PRODUCT_ID" \
    -F "engagement_name=Local Scan - $(date +%Y-%m-%d)" \
    -F "file=@$REPORT" \
    -F "active=true" \
    -F "verified=false" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✔ Imported, test id:', d.get('test'))" 2>/dev/null || echo "✗ Import failed"
fi

echo ""
echo "✔ ZAP scan complete."
