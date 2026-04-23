#!/bin/bash
# Trivy - Container image vulnerability scan
# Usage: bash infra/scripts/trivy.sh [--import-dojo]

set -euo pipefail

REPORTS_DIR="$(cd "$(dirname "$0")/../../reports" && pwd)"
DOJO_URL="${DOJO_URL:-http://localhost:8081}"
DOJO_TOKEN="${DOJO_TOKEN:-}"
DOJO_PRODUCT_NAME="${DOJO_PRODUCT_NAME:-BMI AppSec}"
IMPORT_DOJO="${1:-}"

mkdir -p "$REPORTS_DIR"

echo "========================================"
echo " Trivy - Container Scan"
echo "========================================"

for SERVICE in backend frontend; do
  IMAGE="appsec-bmi-${SERVICE}:latest"
  REPORT="$REPORTS_DIR/trivy-${SERVICE}.json"

  echo ""
  echo "▶ Scanning image: $IMAGE"

  trivy image \
    --format json \
    --output "$REPORT" \
    --severity CRITICAL,HIGH,MEDIUM \
    "$IMAGE"

  VULNS=$(python3 -c "
import json, sys
data = json.load(open('$REPORT'))
total = sum(len(r.get('Vulnerabilities') or []) for r in data.get('Results', []))
print(total)
" 2>/dev/null || echo "?")

  echo "   ✔ Report: $REPORT  |  Vulnerabilities found: $VULNS"

  if [[ "$IMPORT_DOJO" == "--import-dojo" && -n "$DOJO_TOKEN" ]]; then
    echo "   → Importing to DefectDojo..."
    curl -s -X POST "$DOJO_URL/api/v2/import-scan/" \
      -H "Authorization: Token $DOJO_TOKEN" \
      -F "scan_type=Trivy Scan" \
      -F "product_name=$DOJO_PRODUCT_NAME" \
      -F "engagement_name=Local Scan - $(date +%Y-%m-%d)" \
      -F "file=@$REPORT" \
      -F "active=true" \
      -F "verified=false" | python3 -c "import json,sys; d=json.load(sys.stdin); print('   ✔ Imported, test id:', d.get('test'))" 2>/dev/null || echo "   ✗ Import failed"
  fi
done

echo ""
echo "✔ Trivy scan complete. Reports in: $REPORTS_DIR"
