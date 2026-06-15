#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.pi"
source "$ROOT_DIR/scripts/lib/resolve-pi.sh"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Copy .env.pi.example to .env.pi and fill in your Azure values."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

cd "$ROOT_DIR"
PI_BIN="$(resolve_pi_bin)"

if [[ -n "${PI_DEFAULT_MODEL:-}" ]]; then
  exec "$PI_BIN" --model "$PI_DEFAULT_MODEL"
fi

exec "$PI_BIN"
