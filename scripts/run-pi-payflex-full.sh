#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.pi"
PI_HOME="${HOME}/.pi/agent"
MODELS_FILE="${PI_HOME}/models.json"
SETTINGS_FILE="${ROOT_DIR}/.pi/settings.json"
source "$ROOT_DIR/scripts/lib/resolve-pi.sh"

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

strip_quotes() {
  local s="$1"
  if [[ "$s" == \"*\" && "$s" == *\" ]]; then
    s="${s:1:${#s}-2}"
  elif [[ "$s" == \'*\' && "$s" == *\' ]]; then
    s="${s:1:${#s}-2}"
  fi
  printf '%s' "$s"
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  exit 1
fi

BASE_URL=""
API_KEY=""
MODEL_ID=""

while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
  line="$(trim "$raw_line")"
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
  [[ "$line" != *"="* ]] && continue

  key="$(trim "${line%%=*}")"
  value="$(trim "${line#*=}")"
  key="${key#export }"
  value="$(strip_quotes "$value")"

  case "$key" in
    AZURE_FOUNDRY_BASE_URL|AZURE_OPENAI_BASE_URL|endpoint)
      BASE_URL="$value"
      ;;
    AZURE_FOUNDRY_API_KEY|AZURE_OPENAI_API_KEY|api_key)
      API_KEY="$value"
      ;;
    PI_DEFAULT_MODEL|AZURE_FOUNDRY_DEPLOYMENT_NAME|AZURE_OPENAI_DEPLOYMENT_NAME|AZUREDEPLOYMENTNAME|DEPLOYMENT_NAME|deployment_name)
      MODEL_ID="$value"
      ;;
  esac
done < "$ENV_FILE"

if [[ -z "$BASE_URL" || -z "$API_KEY" || -z "$MODEL_ID" ]]; then
  echo "Missing endpoint, API key, or deployment/model name in $ENV_FILE"
  exit 1
fi

BASE_URL="${BASE_URL%/}"
if [[ "$BASE_URL" == */chat/completions ]]; then
  BASE_URL="${BASE_URL%/chat/completions}"
fi

mkdir -p "$PI_HOME" "$ROOT_DIR/.pi"
export AZURE_FOUNDRY_API_KEY="$API_KEY"

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
      "compat": {
        "thinkingFormat": "deepseek"
      },
      "models": [
        {
          "id": "$MODEL_ID",
          "name": "Payflex DeepSeek V4 Pro",
          "reasoning": true,
          "input": ["text", "image"]
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
exec "$PI_BIN" "$@"
