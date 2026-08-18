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

# ---------------------------------------------------------------------------
# 2.1 Limpar state local e cache do provider.
#     O backend é local, então o state de uma rodada anterior (apontando
#     para um project_id que já não existe, ex: projeto de um teste
#     anterior deletado) ficaria "preso" e o Terraform tentaria ler
#     recursos de um projeto inexistente, causando erros de permissão
#     confusos em vez de recriar do zero. Isso torna o script idempotente
#     entre execuções com projetos diferentes.
# ---------------------------------------------------------------------------
if [[ -f terraform.tfstate || -f tfplan ]]; then
  echo "==> State local antigo encontrado. Limpando para execução idempotente..."
  rm -f terraform.tfstate terraform.tfstate.backup tfplan
  rm -rf .terraform
else
  echo "==> Nenhum state local anterior encontrado."
fi

echo "==> terraform init"
terraform init

echo "==> terraform fmt"
terraform fmt

echo "==> terraform validate"
terraform validate

echo "==> terraform plan"
terraform plan -out=tfplan

echo "==> terraform apply"
MAX_APPLY_RETRIES=3
APPLY_RETRY_DELAY=30   # segundos entre tentativas em caso de erro transitório de IAM

attempt=1
while true; do
  # re-gera o plano a cada tentativa: depois de um apply parcial, o state
  # muda, e reaplicar o tfplan antigo falha com "Saved plan is stale".
  terraform plan -out=tfplan

  if terraform apply -auto-approve tfplan; then
    echo "==> Apply concluído com sucesso."
    break
  fi

  if [[ $attempt -ge $MAX_APPLY_RETRIES ]]; then
    echo "Falha no terraform apply após $MAX_APPLY_RETRIES tentativas (provável causa: permissão de IAM que não terminou de propagar, ou erro real de configuração)." >&2
    exit 1
  fi

  echo "==> Apply falhou na tentativa $attempt (possível propagação de IAM ainda em andamento). Aguardando ${APPLY_RETRY_DELAY}s antes de tentar de novo..."
  sleep "$APPLY_RETRY_DELAY"
  attempt=$((attempt + 1))
done