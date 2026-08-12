#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 1/3: Criando projeto GCP e conta de bootstrap..."
"$SCRIPT_DIR/script/account-setup.sh"

echo "==> 2/3: Provisionando infraestrutura via Terraform..."
"$SCRIPT_DIR/script/terraform-setup.sh"

echo "==> 3/3: Configurando secrets/variáveis no GitHub..."
"$SCRIPT_DIR/script/github-secrets-setup.sh"

echo "==> Bootstrap completo! O pipeline CI/CD já pode rodar via push normal."