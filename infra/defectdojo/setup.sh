#!/bin/sh
# Creates a Product and retrieves the API token for CI/CD integration.
# Usage: DOJO_URL=http://localhost:8080 sh setup.sh

DOJO_URL="${DOJO_URL:-http://localhost:8080}"
ADMIN_USER="admin"
ADMIN_PASS="admin@dojo123"

echo "==> Obtaining API token..."
TOKEN=$(curl -s -X POST "$DOJO_URL/api/v2/api-token-auth/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" \
  | sed 's/.*"token":"\([^"]*\)".*/\1/')

echo "Token: $TOKEN"

echo ""
echo "==> Creating product 'BMI AppSec'..."
PRODUCT_ID=$(curl -s -X POST "$DOJO_URL/api/v2/products/" \
  -H "Authorization: Token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"BMI AppSec","description":"BMI calculator AppSec lecture","prod_type":1}' \
  | sed 's/.*"id":\([0-9]*\).*/\1/')

echo "Product ID: $PRODUCT_ID"

echo ""
echo "==> GitHub Actions secrets to configure:"
echo "  DEFECTDOJO_URL=$DOJO_URL"
echo "  DEFECTDOJO_TOKEN=$TOKEN"
echo "  DEFECTDOJO_PRODUCT_ID=$PRODUCT_ID"
