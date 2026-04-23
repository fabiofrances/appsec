#!/bin/sh
# DefectDojo setup — cria produto e engagements por ferramenta
# Usage: bash infra/defectdojo/setup.sh

DOJO_URL="${DOJO_URL:-http://localhost:8081}"
ADMIN_USER="admin"
ADMIN_PASS="admin@dojo123"
PRODUCT_NAME="BMI AppSec"
TODAY=$(date +%Y-%m-%d)
NEXT_YEAR=$(python3 -c "from datetime import date; d=date.today(); print(d.replace(year=d.year+1))")

# ── Token ─────────────────────────────────────────────────────────────────────
echo "==> Obtendo token da API..."
TOKEN=$(curl -s -X POST "$DOJO_URL/api/v2/api-token-auth/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['token'])")
echo "Token: $TOKEN"

# ── Produto ───────────────────────────────────────────────────────────────────
echo ""
echo "==> Verificando produto '$PRODUCT_NAME'..."

ENCODED_NAME=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PRODUCT_NAME'))")
PRODUCT_ID=$(curl -s "$DOJO_URL/api/v2/products/?name=$ENCODED_NAME" \
  -H "Authorization: Token $TOKEN" \
  | python3 -c "import json,sys; r=json.load(sys.stdin); print(r['results'][0]['id'] if r.get('count',0)>0 else '')" 2>/dev/null)

if [ -z "$PRODUCT_ID" ]; then
  echo "   → Produto nao encontrado, criando..."
  PRODUCT_ID=$(curl -s -X POST "$DOJO_URL/api/v2/products/" \
    -H "Authorization: Token $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$PRODUCT_NAME\",\"description\":\"BMI calculator — palestra AppSec\",\"prod_type\":1}" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))")
fi

if [ -z "$PRODUCT_ID" ]; then
  echo "   ERRO: nao foi possivel obter o Product ID. Verifique o DefectDojo."
  exit 1
fi
echo "   Produto ID: $PRODUCT_ID"

# ── Engagements ───────────────────────────────────────────────────────────────
# Mensagens vao para stderr (>&2) para nao contaminar o valor retornado
create_engagement() {
  NAME="$1"
  DESC="$2"

  ENCODED_ENG=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$NAME'))")
  ENG_ID=$(curl -s "$DOJO_URL/api/v2/engagements/?product=$PRODUCT_ID&name=$ENCODED_ENG" \
    -H "Authorization: Token $TOKEN" \
    | python3 -c "import json,sys; r=json.load(sys.stdin); print(r['results'][0]['id'] if r.get('count',0)>0 else '')" 2>/dev/null)

  if [ -z "$ENG_ID" ]; then
    ENG_ID=$(curl -s -X POST "$DOJO_URL/api/v2/engagements/" \
      -H "Authorization: Token $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"$NAME\",\"description\":\"$DESC\",\"product\":$PRODUCT_ID,\"target_start\":\"$TODAY\",\"target_end\":\"$NEXT_YEAR\",\"engagement_type\":\"CI/CD\",\"status\":\"In Progress\"}" \
      | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
    echo "   ✔ Criado: $NAME (ID: $ENG_ID)" >&2
  else
    echo "   ✔ Ja existe: $NAME (ID: $ENG_ID)" >&2
  fi

  printf '%s' "$ENG_ID"
}

echo ""
echo "==> Criando engagements..."
ENG_TRIVY=$(create_engagement    "Container Scan - Trivy"  "CVE scan nas imagens Docker usando Trivy")
ENG_DEPCHECK=$(create_engagement "SCA - Dependency Check"  "Software Composition Analysis com OWASP Dependency Check")
ENG_ZAP=$(create_engagement      "DAST - OWASP ZAP"        "Dynamic Application Security Testing com OWASP ZAP")

# ── Output ────────────────────────────────────────────────────────────────────
echo ""
echo "==> Exporte as variaveis abaixo antes de rodar os scans:"
echo ""
echo "  export DOJO_TOKEN=$TOKEN"
echo "  export DOJO_ENG_TRIVY=$ENG_TRIVY"
echo "  export DOJO_ENG_DEPCHECK=$ENG_DEPCHECK"
echo "  export DOJO_ENG_ZAP=$ENG_ZAP"
echo ""
echo "==> Secrets para GitHub Actions:"
echo "  DEFECTDOJO_URL=$DOJO_URL"
echo "  DEFECTDOJO_TOKEN=$TOKEN"
echo "  DEFECTDOJO_ENG_TRIVY=$ENG_TRIVY"
echo "  DEFECTDOJO_ENG_DEPCHECK=$ENG_DEPCHECK"
echo "  DEFECTDOJO_ENG_ZAP=$ENG_ZAP"
