#!/bin/sh
# DefectDojo setup — cria produto e engagements por ferramenta
# Usage: bash infra/defectdojo/setup.sh

DOJO_URL="${DOJO_URL:-http://localhost:8081}"
ADMIN_USER="admin"
ADMIN_PASS="admin@dojo123"
PRODUCT_NAME="BMI AppSec"
TODAY=$(date +%Y-%m-%d)
NEXT_YEAR=$(python3 -c "from datetime import date, timedelta; print((date.today().replace(year=date.today().year+1)).strftime('%Y-%m-%d'))")

echo "==> Obtendo token da API..."
TOKEN=$(curl -s -X POST "$DOJO_URL/api/v2/api-token-auth/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
echo "Token: $TOKEN"

# ── Produto ──────────────────────────────────────────────────────────────────
echo ""
echo "==> Verificando produto '$PRODUCT_NAME'..."
PRODUCT_ID=$(curl -s "$DOJO_URL/api/v2/products/?name=$PRODUCT_NAME" \
  -H "Authorization: Token $TOKEN" \
  | python3 -c "import json,sys; r=json.load(sys.stdin); print(r['results'][0]['id'] if r['count']>0 else '')" 2>/dev/null)

if [ -z "$PRODUCT_ID" ]; then
  echo "   → Criando produto..."
  PRODUCT_ID=$(curl -s -X POST "$DOJO_URL/api/v2/products/" \
    -H "Authorization: Token $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$PRODUCT_NAME\",\"description\":\"BMI calculator — palestra AppSec\",\"prod_type\":1}" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "   ✔ Produto criado — ID: $PRODUCT_ID"
else
  echo "   ✔ Produto já existe — ID: $PRODUCT_ID"
fi

# ── Engagements ───────────────────────────────────────────────────────────────
create_engagement() {
  NAME=$1
  DESC=$2

  ENG_ID=$(curl -s "$DOJO_URL/api/v2/engagements/?product=$PRODUCT_ID&name=$NAME" \
    -H "Authorization: Token $TOKEN" \
    | python3 -c "import json,sys; r=json.load(sys.stdin); print(r['results'][0]['id'] if r['count']>0 else '')" 2>/dev/null)

  if [ -z "$ENG_ID" ]; then
    ENG_ID=$(curl -s -X POST "$DOJO_URL/api/v2/engagements/" \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"$NAME\",\"description\":\"$DESC\",\"product\":$PRODUCT_ID,\"target_start\":\"$TODAY\",\"target_end\":\"$NEXT_YEAR\",\"engagement_type\":\"CI/CD\",\"status\":\"In Progress\"}" \
      | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
    echo "   ✔ Engagement criado: $NAME (ID: $ENG_ID)"
  else
    echo "   ✔ Engagement já existe: $NAME (ID: $ENG_ID)"
  fi

  echo "$ENG_ID"
}

echo ""
echo "==> Criando engagements..."
ENG_TRIVY=$(create_engagement    "Container Scan - Trivy"         "CVE scan nas imagens Docker usando Trivy")
ENG_DEPCHECK=$(create_engagement "SCA - Dependency Check"         "Software Composition Analysis com OWASP Dependency Check")
ENG_ZAP=$(create_engagement      "DAST - OWASP ZAP"               "Dynamic Application Security Testing com OWASP ZAP")

# ── Output ────────────────────────────────────────────────────────────────────
echo ""
echo "==> Exporte as variáveis abaixo antes de rodar os scans:"
echo ""
echo "  export DOJO_TOKEN=$TOKEN"
echo "  export DOJO_PRODUCT_NAME=\"$PRODUCT_NAME\""
echo "  export DOJO_ENG_TRIVY=$ENG_TRIVY"
echo "  export DOJO_ENG_DEPCHECK=$ENG_DEPCHECK"
echo "  export DOJO_ENG_ZAP=$ENG_ZAP"
echo ""
echo "==> Secrets para GitHub Actions:"
echo "  DEFECTDOJO_URL=$DOJO_URL"
echo "  DEFECTDOJO_TOKEN=$TOKEN"
echo "  DEFECTDOJO_PRODUCT_NAME=$PRODUCT_NAME"
echo "  DEFECTDOJO_ENG_TRIVY=$ENG_TRIVY"
echo "  DEFECTDOJO_ENG_DEPCHECK=$ENG_DEPCHECK"
echo "  DEFECTDOJO_ENG_ZAP=$ENG_ZAP"
