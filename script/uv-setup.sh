#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

cd "$PROJECT_DIR"

echo "Projeto: $PROJECT_DIR"

if ! command -v uv >/dev/null 2>&1; then
  echo "Instalando uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "uv já está instalado: $(uv --version)"
fi

if [[ ! -f "$PROJECT_DIR/pyproject.toml" ]]; then
  uv init
else
  echo "pyproject.toml já existe; uv init não será executado."
fi

export UV_LINK_MODE=copy
uv sync

echo "Ambiente virtual criado/sincronizado."
echo "Para ativar o ambiente, execute: source \"$PROJECT_DIR/.venv/bin/activate\""