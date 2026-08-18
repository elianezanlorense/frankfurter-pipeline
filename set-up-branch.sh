#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
BRANCH_NAME="${1:-test}"

LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-branch_$(date +%Y%m%d_%H%M%S).log"

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

run() {
    log INFO "$*"
    "$@" 2>&1 | tee -a "$LOG_FILE"
}

add_alias() {
    local alias_line="$1"

    if ! grep -qxF "$alias_line" "$SHELL_RC" 2>/dev/null; then
        echo "$alias_line" >> "$SHELL_RC"
        log INFO "Alias adicionado: $alias_line"
    else
        log INFO "Alias já existe: $alias_line"
    fi
}

cd "$PROJECT_DIR"

log INFO "Iniciando configuração do projeto."
log INFO "Projeto: $PROJECT_DIR"
log INFO "Log: $LOG_FILE"

run git status --short
run git fetch origin
run git switch main
run git pull --ff-only origin main

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    log INFO "Branch local '$BRANCH_NAME' já existe."
    run git switch "$BRANCH_NAME"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    log INFO "Criando branch local a partir de origin/$BRANCH_NAME."
    run git switch --track "origin/$BRANCH_NAME"
else
    log INFO "Criando branch '$BRANCH_NAME' a partir da main."
    run git switch -c "$BRANCH_NAME"
fi

log INFO "Branch atual: $(git branch --show-current)"

if [[ "${SHELL:-}" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

touch "$SHELL_RC"

add_alias "alias st='git status'"
add_alias "alias sw='git switch'"
add_alias "alias br='git branch'"
add_alias "alias co='git checkout'"
add_alias "alias cm='git commit'"
add_alias "alias ps='git push'"
add_alias "alias pl='git pull'"
add_alias "alias ga='git add'"
add_alias "alias lg='git log --oneline --graph --decorate --all'"

if ! command -v uv >/dev/null 2>&1; then
    log INFO "Instalando uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    log INFO "uv já está instalado: $(uv --version)"
fi

if [[ ! -f "$PROJECT_DIR/pyproject.toml" ]]; then
    run uv init
else
    log INFO "pyproject.toml já existe; uv init não será executado."
fi

export UV_LINK_MODE=copy
run uv sync

log INFO "Aliases configurados em $SHELL_RC."
log INFO "Branch pronta: $(git branch --show-current)"
log INFO "Ambiente virtual criado/sincronizado."
log INFO "Depois do script, execute: source \"$SHELL_RC\""
log INFO "Para ativar o ambiente, execute: source \"$PROJECT_DIR/.venv/bin/activate\""