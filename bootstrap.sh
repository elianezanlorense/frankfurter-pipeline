#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SCRIPT_DIR/script/log.sh"



chmod +x "$SCRIPT_DIR"/script/*.sh

export LOG_FILE="$SCRIPT_DIR/logs/bootstrap_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

#"$LOG" "$SCRIPT_DIR/script/branch-setup.sh" "$BRANCH_NAME"
#"$LOG" "$SCRIPT_DIR/script/uv-setup.sh"
"$LOG" "$SCRIPT_DIR/script/account-setup.sh"
"$LOG" "$SCRIPT_DIR/script/terraform-setup.sh"
"$LOG" "$SCRIPT_DIR/script/github-secrets-setup.sh"