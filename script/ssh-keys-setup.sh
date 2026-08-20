#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$PROJECT_DIR"

KEY_PATH="/tmp/airflow-deploy-key"
DEPLOY_KEY_TITLE="airflow-git-sync"

echo "==> Verificando se os secrets SSH já existem no repositório..."
EXISTING_SECRETS="$(gh secret list --json name -q '.[].name' 2>/dev/null || true)"

if grep -qx "SSH_PRIVATE_KEY" <<< "$EXISTING_SECRETS" && grep -qx "SSH_PUBLIC_KEY" <<< "$EXISTING_SECRETS"; then
  echo "==> SSH_PRIVATE_KEY e SSH_PUBLIC_KEY já existem. Pulando geração de chave."
else
  echo "==> Gerando novo par de chaves SSH..."
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$DEPLOY_KEY_TITLE"

  echo "==> Configurando secrets no GitHub..."
  gh secret set SSH_PRIVATE_KEY < "$KEY_PATH"
  gh secret set SSH_PUBLIC_KEY < "$KEY_PATH.pub"

  echo "==> Verificando se a deploy key já existe no repositório..."
  if gh repo deploy-key list --json title -q '.[].title' 2>/dev/null | grep -qx "$DEPLOY_KEY_TITLE"; then
    echo "==> Deploy key '$DEPLOY_KEY_TITLE' já existe. Pulando."
  else
    echo "==> Adicionando deploy key (somente leitura)..."
    gh repo deploy-key add "$KEY_PATH.pub" --title "$DEPLOY_KEY_TITLE" --read-only
  fi

  echo "==> Limpando chaves do disco local..."
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
fi

echo "==> Chaves SSH configuradas."