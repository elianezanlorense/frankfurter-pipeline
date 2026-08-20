#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# log - roda qualquer comando silenciosamente, escrevendo tudo (stdout +
#       stderr) num arquivo de log, sem nada aparecer no terminal.
#
# USO:
#   log <comando> [argumentos...]
#
# EXEMPLOS:
#   log terraform apply -auto-approve
#   log gcloud projects list
#   log ./meu-script.sh
#
# Por padrão cria um arquivo novo por execução em ~/logs/, nomeado com
# timestamp + nome do comando. Para acumular várias execuções no MESMO
# arquivo (ex: dentro de uma sessão de trabalho), exporte LOG_FILE antes:
#
#   export LOG_FILE=~/logs/minha-sessao.log
#   log terraform init
#   log terraform plan
#   log terraform apply -auto-approve
#
# O código de saída (exit code) do comando original é preservado — então
# `log meu-comando && echo ok` continua funcionando normalmente, mesmo sem
# nada aparecer na tela.
# ---------------------------------------------------------------------------
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Uso: log <comando> [argumentos...]" >&2
  exit 1
fi

LOG_DIR="${LOG_DIR:-$HOME/logs}"
mkdir -p "$LOG_DIR"

if [[ -z "${LOG_FILE:-}" ]]; then
  CMD_NAME="$(basename "$1")"
  LOG_FILE="$LOG_DIR/${CMD_NAME}_$(date +%Y%m%d_%H%M%S).log"
fi

{
  echo "───────────────────────────────────────────────────────"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executando: $*"
  echo "───────────────────────────────────────────────────────"
} >> "$LOG_FILE"

set +e
"$@" >> "$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Encerrado com código: $EXIT_CODE" >> "$LOG_FILE"

exit "$EXIT_CODE"