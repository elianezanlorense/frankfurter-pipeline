#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
BRANCH_NAME="${1:-test}"

add_alias() {
  local alias_line="$1"

  if ! grep -qxF "$alias_line" "$SHELL_RC" 2>/dev/null; then
    echo "$alias_line" >> "$SHELL_RC"
    echo "Alias adicionado: $alias_line"
  else
    echo "Alias já existe: $alias_line"
  fi
}

cd "$PROJECT_DIR"

echo "Projeto: $PROJECT_DIR"

git status --short
git fetch origin
git switch main
git pull --ff-only origin main

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo "Branch local '$BRANCH_NAME' já existe."
  git switch "$BRANCH_NAME"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
  echo "Criando branch local a partir de origin/$BRANCH_NAME."
  git switch --track "origin/$BRANCH_NAME"
else
  echo "Criando branch '$BRANCH_NAME' a partir da main."
  git switch -c "$BRANCH_NAME"
fi

echo "Branch atual: $(git branch --show-current)"

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

echo "Aliases configurados em $SHELL_RC."
echo "Branch pronta: $(git branch --show-current)"
echo "Depois do script, execute: source \"$SHELL_RC\""