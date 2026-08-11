#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform/state"   # ajuste se o caminho for diferente
SA_ACCOUNT_ID="github-actions-tf"            # account_id da service account no state.tf

# ---------------------------------------------------------------------------
# 1. Autenticar no GitHub CLI (evita interferência do token do Codespace)
# ---------------------------------------------------------------------------
unset GITHUB_TOKEN || true

if ! gh auth status >/dev/null 2>&1; then
  echo "==> Autenticando no GitHub CLI..."
  gh auth login --hostname github.com --git-protocol https --scopes repo,workflow
fi

gh auth status
echo "==> Usuário GitHub: $(gh api user --jq '.login')"

# ---------------------------------------------------------------------------
# 2. Coletar informações do projeto GCP
# ---------------------------------------------------------------------------
PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERRO: nenhum projeto GCP configurado. Rode 'gcloud config set project SEU_PROJECT_ID' antes." >&2
  exit 1
fi

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")"
SA_EMAIL="${SA_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

# ---------------------------------------------------------------------------
# 3. Ler os IDs reais do pool/provider DIRETO DO TERRAFORM STATE
#    (evita desalinhamento caso os nomes tenham sido gerados dinamicamente
#    e sejam diferentes dos defaults do variables.tf)
# ---------------------------------------------------------------------------
echo "==> Lendo IDs reais do Terraform state em $TERRAFORM_DIR ..."
pushd "$TERRAFORM_DIR" >/dev/null

WORKLOAD_IDENTITY_POOL_ID="$(terraform state show google_iam_workload_identity_pool.github 2>/dev/null \
  | grep 'workload_identity_pool_id' | awk -F'"' '{print $2}')"

WORKLOAD_IDENTITY_PROVIDER_ID="$(terraform state show google_iam_workload_identity_pool_provider.github 2>/dev/null \
  | grep 'workload_identity_pool_provider_id' | awk -F'"' '{print $2}')"

popd >/dev/null

if [[ -z "$WORKLOAD_IDENTITY_POOL_ID" || -z "$WORKLOAD_IDENTITY_PROVIDER_ID" ]]; then
  echo "ERRO: não foi possível ler o pool/provider do Terraform state." >&2
  echo "Confirme que 'terraform apply' já rodou com sucesso em $TERRAFORM_DIR" >&2
  exit 1
fi

# Monta o resource name completo do Workload Identity Provider
WORKLOAD_IDENTITY_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}"

echo ""
echo "==> Project ID: $PROJECT_ID"
echo "==> Project Number: $PROJECT_NUMBER"
echo "==> Service Account: $SA_EMAIL"
echo "==> Workload Identity Pool ID: $WORKLOAD_IDENTITY_POOL_ID"
echo "==> Workload Identity Provider ID: $WORKLOAD_IDENTITY_PROVIDER_ID"
echo "==> Workload Identity Provider (resource name): $WORKLOAD_IDENTITY_PROVIDER"
echo ""

# ---------------------------------------------------------------------------
# 3. Validar que os recursos realmente existem antes de gravar no GitHub
#    (evita configurar o workflow com um provider que não existe)
# ---------------------------------------------------------------------------
echo "==> Validando se a service account existe..."
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "ERRO: a service account $SA_EMAIL não existe. Rode o terraform apply primeiro." >&2
  exit 1
fi

echo "==> Validando se o Workload Identity Provider existe..."
if ! gcloud iam workload-identity-pools providers describe "$WORKLOAD_IDENTITY_PROVIDER_ID" \
  --workload-identity-pool="$WORKLOAD_IDENTITY_POOL_ID" \
  --location="global" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "ERRO: o Workload Identity Provider não existe. Rode o terraform apply primeiro." >&2
  exit 1
fi

echo "==> Recursos confirmados."
echo ""

# ---------------------------------------------------------------------------
# 4. Enviar variáveis para o GitHub (não são segredos, são identificadores
#    públicos - WIF não usa nenhuma credencial estática)
# ---------------------------------------------------------------------------
echo "==> Configurando GitHub Variables..."
gh variable set GCP_PROJECT_ID --body="$PROJECT_ID"
gh variable set GCP_SERVICE_ACCOUNT --body="$SA_EMAIL"
gh variable set GCP_WORKLOAD_IDENTITY_PROVIDER --body="$WORKLOAD_IDENTITY_PROVIDER"

# ---------------------------------------------------------------------------
# 5. (Opcional) Chaves SSH, se o seu pipeline precisar delas
#    Só executa se os arquivos existirem
# ---------------------------------------------------------------------------
if [[ -f ~/.ssh/airflow_vm ]]; then
  echo "==> Enviando SSH_PRIVATE_KEY..."
  gh secret set SSH_PRIVATE_KEY < ~/.ssh/airflow_vm
fi

if [[ -f ~/.ssh/airflow_vm.pub ]]; then
  echo "==> Enviando SSH_PUBLIC_KEY..."
  gh secret set SSH_PUBLIC_KEY < ~/.ssh/airflow_vm.pub
fi

# ---------------------------------------------------------------------------
# 6. Conferir
# ---------------------------------------------------------------------------
echo ""
echo "==> Secrets configurados:"
gh secret list

echo ""
echo "==> Variables configuradas:"
gh variable list

echo ""
echo "==> Concluído. Nenhuma chave JSON de service account foi criada ou armazenada."