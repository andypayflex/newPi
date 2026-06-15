#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.pi"
PI_HOME="${HOME}/.pi/agent"
MODELS_FILE="${PI_HOME}/models.json"
SETTINGS_FILE="${ROOT_DIR}/.pi/settings.json"
source "$ROOT_DIR/scripts/lib/resolve-pi.sh"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Create it and add your endpoint, deployment name, and API key."
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

BASE_URL="${AZURE_FOUNDRY_BASE_URL:-${AZURE_OPENAI_BASE_URL:-}}"
API_KEY="${AZURE_FOUNDRY_API_KEY:-${AZURE_OPENAI_API_KEY:-}}"
MODEL_ID="${PI_DEFAULT_MODEL:-${AZURE_FOUNDRY_DEPLOYMENT_NAME:-${AZURE_OPENAI_DEPLOYMENT_NAME:-${DEPLOYMENT_NAME:-}}}}"

if [[ -z "$BASE_URL" ]]; then
  echo "Missing AZURE_FOUNDRY_BASE_URL or AZURE_OPENAI_BASE_URL in $ENV_FILE"
  exit 1
fi

if [[ -z "$API_KEY" ]]; then
  echo "Missing AZURE_FOUNDRY_API_KEY or AZURE_OPENAI_API_KEY in $ENV_FILE"
  exit 1
fi

if [[ -z "$MODEL_ID" ]]; then
  echo "Missing deployment/model name in $ENV_FILE"
  echo "Set one of: PI_DEFAULT_MODEL, AZURE_FOUNDRY_DEPLOYMENT_NAME, AZURE_OPENAI_DEPLOYMENT_NAME, DEPLOYMENT_NAME"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
if [[ "$BASE_URL" == */chat/completions ]]; then
  BASE_URL="${BASE_URL%/chat/completions}"
fi

mkdir -p "$PI_HOME" "$ROOT_DIR/.pi"

cat > "$MODELS_FILE" <<EOF
{
  "providers": {
    "azure-foundry": {
      "baseUrl": "$BASE_URL",
      "api": "openai-completions",
      "apiKey": "\$AZURE_FOUNDRY_API_KEY",
      "headers": {
        "api-key": "\$AZURE_FOUNDRY_API_KEY"
      },
      "models": [
        {
          "id": "$MODEL_ID",
          "name": "Payflex Foundry",
          "input": ["text", "image"],
          "reasoning": true
        }
      ]
    }
  }
}
EOF

cat > "$SETTINGS_FILE" <<EOF
{
  "defaultProvider": "azure-foundry",
  "defaultModel": "$MODEL_ID",
  "defaultThinkingLevel": "medium"
}
EOF

cd "$ROOT_DIR"
PI_BIN="$(resolve_pi_bin)"
exec "$PI_BIN" --model "$MODEL_ID"
