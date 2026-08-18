#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# LOGGING
# ---------------------------------------------------------------------------
LOG_DIR="$SCRIPT_DIR/logs"
if [[ -d "$LOG_DIR" ]]; then
  echo "==> Diretório de logs já existe: $LOG_DIR"
else
  echo "==> Criando diretório de logs: $LOG_DIR"
  mkdir -p "$LOG_DIR"
fi
LOG_FILE="$LOG_DIR/bootstrap_$(date +%Y%m%d_%H%M%S).log"

log() {
  local level="$1"
  shift
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

run() {
  log INFO "Executando: $*"
  "$@" >> "$LOG_FILE" 2>&1
}

# ---------------------------------------------------------------------------
# STEPS
# ---------------------------------------------------------------------------
log INFO "Garantindo permissão de execução em todos os scripts..."
chmod +x "$SCRIPT_DIR"/script/*.sh

log INFO "==> 1/3: Criando projeto GCP e conta de bootstrap..."
run "$SCRIPT_DIR/script/account-setup.sh"

log INFO "==> 2/3: Provisionando infraestrutura via Terraform..."
run "$SCRIPT_DIR/script/terraform-setup.sh"

log INFO "==> 3/3: Configurando secrets/variáveis no GitHub..."
run "$SCRIPT_DIR/script/github-secrets-setup.sh"

log INFO "==> Bootstrap completo! O pipeline CI/CD já pode rodar via push normal."
log INFO "Log completo salvo em: $LOG_FILE"