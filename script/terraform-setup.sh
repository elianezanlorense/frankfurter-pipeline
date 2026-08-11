#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$REPO_ROOT/terraform/state"   # ajuste se o caminho for diferente

# ---------------------------------------------------------------------------
# 1. Instalar Terraform (só se ainda não estiver instalado)
# ---------------------------------------------------------------------------
if ! command -v terraform >/dev/null 2>&1; then
  echo "==> Terraform não encontrado. Instalando..."

  wget -O - https://apt.releases.hashicorp.com/gpg |
    sudo gpg --batch --yes --dearmor \
      -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

  DIST_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${DIST_CODENAME} main" |
    sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y terraform
else
  echo "==> Terraform já instalado, pulando instalação."
fi

terraform version

# ---------------------------------------------------------------------------
# 1.5 Garantir que as variáveis necessárias existem neste shell,
#     independente de terem sido exportadas antes (evita prompt interativo)
# ---------------------------------------------------------------------------
if [[ -z "${TF_VAR_project_id:-}" ]]; then
  echo "==> TF_VAR_project_id não encontrada no ambiente. Detectando automaticamente..."
  export TF_VAR_project_id="$(gcloud config get-value project 2>/dev/null)"
fi

if [[ -z "${TF_VAR_project_id}" ]]; then
  echo "ERRO: não foi possível detectar o project_id automaticamente." >&2
  echo "Rode 'gcloud config set project SEU_PROJECT_ID' antes, ou exporte TF_VAR_project_id manualmente." >&2
  exit 1
fi

if [[ -z "${TF_VAR_github_repository:-}" ]]; then
  echo "==> TF_VAR_github_repository não encontrada no ambiente. Detectando automaticamente..."
  export TF_VAR_github_repository="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
fi

if [[ -z "${TF_VAR_github_repository}" ]]; then
  echo "ERRO: não foi possível detectar o repositório GitHub automaticamente." >&2
  echo "Rode este script de dentro do clone do repositório, ou exporte TF_VAR_github_repository manualmente." >&2
  exit 1
fi

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  if [[ -f /tmp/tf-bootstrap-key.json ]]; then
    echo "==> GOOGLE_APPLICATION_CREDENTIALS não encontrada no ambiente. Reutilizando chave existente em /tmp/tf-bootstrap-key.json..."
    export GOOGLE_APPLICATION_CREDENTIALS="/tmp/tf-bootstrap-key.json"
  else
    echo "AVISO: GOOGLE_APPLICATION_CREDENTIALS não está definida e /tmp/tf-bootstrap-key.json não existe."
    echo "Rode o account-setup.sh primeiro, ou 'gcloud auth application-default login' antes de continuar."
  fi
fi

echo "==> project_id: $TF_VAR_project_id"
echo "==> github_repository: $TF_VAR_github_repository"
echo "==> credenciais: ${GOOGLE_APPLICATION_CREDENTIALS:-<não definido>}"

# ---------------------------------------------------------------------------
# 2. Rodar o fluxo Terraform
# ---------------------------------------------------------------------------
echo "==> Entrando em $TERRAFORM_DIR ..."
cd "$TERRAFORM_DIR"

echo "==> terraform init"
terraform init

echo "==> terraform fmt"
terraform fmt

echo "==> terraform validate"
terraform validate

echo "==> terraform plan"
terraform plan -out=tfplan

echo "==> terraform apply"
terraform apply -auto-approve tfplan
echo "==> Apply concluído com sucesso."