#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
MAX_RETRIES=6
RETRY_DELAY=30   # segundos entre tentativas em caso de erro 429

# ---------------------------------------------------------------------------
# 1. Instalar gcloud CLI (só se ainda não estiver instalado)
# ---------------------------------------------------------------------------
if ! command -v gcloud >/dev/null 2>&1; then
  echo "==> gcloud não encontrado. Instalando..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates gnupg curl

  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

  sudo apt-get update -y
  sudo apt-get install -y google-cloud-cli
else
  echo "==> gcloud já instalado, pulando instalação."
fi

gcloud version

# ---------------------------------------------------------------------------
# 2. Autenticação de usuário
# ---------------------------------------------------------------------------
echo "==> Autenticando no Google Cloud..."
gcloud auth login

# ---------------------------------------------------------------------------
# 3. Criar projeto (com retry em caso de 429 - rate limit do quota project padrão)
# ---------------------------------------------------------------------------
PROJECT_ID="zoocamp-project-$(shuf -i 100000-999999 -n 1)"
echo "==> Criando projeto: $PROJECT_ID"

attempt=1
while true; do
  if gcloud projects create "$PROJECT_ID" --name="$PROJECT_ID" --quiet; then
    echo "==> Projeto criado com sucesso."
    break
  fi

  if [[ $attempt -ge $MAX_RETRIES ]]; then
    echo "Falha ao criar projeto após $MAX_RETRIES tentativas (provável rate limit persistente ou restrição de organização)." >&2
    exit 1
  fi

  echo "==> Falha na tentativa $attempt (possível rate limit 429). Aguardando ${RETRY_DELAY}s antes de tentar de novo..."
  sleep "$RETRY_DELAY"
  attempt=$((attempt + 1))
done

gcloud config set project "$PROJECT_ID"

# ---------------------------------------------------------------------------
# 4. Vincular conta de faturamento
# ---------------------------------------------------------------------------
echo "==> Vinculando conta de faturamento..."
BILLING_ACCOUNT_ID="$(gcloud billing accounts list --filter="open=true" --format="value(name)" --limit=1 | sed 's#^billingAccounts/##')"
if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
  echo "Nenhuma conta de faturamento aberta encontrada." >&2
  exit 1
fi
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"

# ---------------------------------------------------------------------------
# 5. Habilitar APIs mínimas
# ---------------------------------------------------------------------------
echo "==> Habilitando APIs mínimas..."
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  --project="$PROJECT_ID"

# ---------------------------------------------------------------------------
# 6. Criar service account de bootstrap (temporária) + chave
# ---------------------------------------------------------------------------
echo "==> Criando service account de bootstrap (temporária)..."
gcloud iam service-accounts create tf-bootstrap \
  --project="$PROJECT_ID" \
  --display-name="Terraform Bootstrap"

# pequena espera para propagação de IAM
sleep 10

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:tf-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/owner" \
  --condition=None

echo "==> Gerando chave temporária da service account..."
gcloud iam service-accounts keys create /tmp/tf-bootstrap-key.json \
  --iam-account="tf-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com"

export GOOGLE_APPLICATION_CREDENTIALS="/tmp/tf-bootstrap-key.json"
export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_github_repository="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

echo ""
echo "Project ID: $PROJECT_ID"
echo "Billing account: $BILLING_ACCOUNT_ID"
echo "GitHub repository: $TF_VAR_github_repository"
echo "Credenciais: $GOOGLE_APPLICATION_CREDENTIALS"
echo ""
echo "==> Bootstrap de conta/projeto concluído."
echo "==> As variáveis TF_VAR_project_id, TF_VAR_github_repository e"
echo "    GOOGLE_APPLICATION_CREDENTIALS já estão exportadas neste shell."
echo ""
echo "==> IMPORTANTE: a service account 'tf-bootstrap' tem role roles/owner."
echo "    Quando não precisar mais dela, apague-a com:"
echo ""
echo "      KEY_ID=\$(gcloud iam service-accounts keys list \\"
echo "        --iam-account=\"tf-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com\" \\"
echo "        --managed-by=user --format=\"value(name)\")"
echo "      gcloud iam service-accounts keys delete \"\$KEY_ID\" \\"
echo "        --iam-account=\"tf-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com\" --quiet"
echo "      rm -f /tmp/tf-bootstrap-key.json"
echo "      gcloud iam service-accounts delete \"tf-bootstrap@${PROJECT_ID}.iam.gserviceaccount.com\" --quiet"