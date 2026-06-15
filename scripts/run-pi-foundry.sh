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

RUNTIME_BASE_URL="$BASE_URL"
CAPTURE_LLM_REQUESTS="${PI_CAPTURE_LLM_REQUESTS:-0}"
PROXY_PID=""

if [[ "$CAPTURE_LLM_REQUESTS" == "1" || "$CAPTURE_LLM_REQUESTS" == "true" ]]; then
  if ! command -v node >/dev/null 2>&1; then
    echo "PI_CAPTURE_LLM_REQUESTS requires node on PATH"
    exit 1
  fi

  PROXY_HOST="${PI_LLM_PROXY_HOST:-127.0.0.1}"
  PROXY_PORT="${PI_LLM_PROXY_PORT:-8787}"
  PROXY_LOG_DIR="${PI_LLM_PROXY_LOG_DIR:-$ROOT_DIR/.pi/llm-request-captures}"
  RUNTIME_BASE_URL="http://${PROXY_HOST}:${PROXY_PORT}"

  PI_LLM_PROXY_TARGET_BASE_URL="$BASE_URL" \
    PI_LLM_PROXY_API_KEY="$API_KEY" \
    PI_LLM_PROXY_HOST="$PROXY_HOST" \
    PI_LLM_PROXY_PORT="$PROXY_PORT" \
    PI_LLM_PROXY_LOG_DIR="$PROXY_LOG_DIR" \
    node "$ROOT_DIR/scripts/llm-request-proxy.mjs" &
  PROXY_PID="$!"

  cleanup_proxy() {
    if [[ -n "$PROXY_PID" ]] && kill -0 "$PROXY_PID" >/dev/null 2>&1; then
      kill "$PROXY_PID" >/dev/null 2>&1 || true
      wait "$PROXY_PID" >/dev/null 2>&1 || true
    fi
  }
  trap cleanup_proxy EXIT INT TERM

  sleep 0.5
  if ! kill -0 "$PROXY_PID" >/dev/null 2>&1; then
    wait "$PROXY_PID"
    exit 1
  fi
fi

cat > "$MODELS_FILE" <<EOF
{
  "providers": {
    "azure-foundry": {
      "baseUrl": "$RUNTIME_BASE_URL",
      "api": "openai-completions",
      "apiKey": "\$AZURE_FOUNDRY_API_KEY",
      "headers": {
        "api-key": "\$AZURE_FOUNDRY_API_KEY"
      },
      "models": [
        {
          "id": "$MODEL_ID",
          "name": "Payflex Foundry",
          "input": ["text"],
          "reasoning": true,
          "contextWindow": 1000000,
          "maxTokens": 384000
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

PI_BIN="$(resolve_pi_bin)"
if [[ -n "$PROXY_PID" ]]; then
  "$PI_BIN" --provider azure-foundry --model "$MODEL_ID" "$@"
else
  exec "$PI_BIN" --provider azure-foundry --model "$MODEL_ID" "$@"
fi
