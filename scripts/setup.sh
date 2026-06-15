#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.pi"
ENV_EXAMPLE="$ROOT_DIR/.env.pi.example"

# ── Colours ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { printf "${CYAN}●${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${NC} %s\n" "$*"; }
err()   { printf "${RED}✗${NC} %s\n" "$*"; }

# ── Step 1: Prerequisites ────────────────────────────────────────────
header() { printf "\n${CYAN}══ %s ══${NC}\n" "$*"; }

header "Step 1 – Prerequisites"

NODE_OK=0; NPM_OK=0

if command -v node &>/dev/null; then
  NODE_VER="$(node --version)"
  ok "node found: $NODE_VER"
  NODE_OK=1
else
  err "node not found – install Node 18+ (https://nodejs.org)"
fi

if command -v npm &>/dev/null; then
  NPM_VER="$(npm --version)"
  ok "npm found: v$NPM_VER"
  NPM_OK=1
else
  err "npm not found – it should come with Node"
fi

if command -v git &>/dev/null; then
  ok "git found"
else
  warn "git not found – recommend installing for package updates"
fi

# ── Step 2: Install Pi ───────────────────────────────────────────────
header "Step 2 – Install Pi"

PI_BIN=""
for candidate in \
  "$HOME/.local/node-v22/bin/pi" \
  "$HOME/.local/node-v22.22.3/bin/pi" \
  "/usr/local/bin/pi" \
  "/usr/bin/pi"
do
  if [[ -x "$candidate" ]]; then
    PI_BIN="$candidate"
    break
  fi
done

if [[ -z "$PI_BIN" ]]; then
  PI_BIN="$(command -v pi 2>/dev/null || true)"
fi

if [[ -n "$PI_BIN" && "$(basename "$PI_BIN")" != "pi" ]] 2>/dev/null; then
  PI_BIN=""
fi

if [[ -n "$PI_BIN" ]]; then
  PI_VER="$("$PI_BIN" --version 2>/dev/null || echo "unknown")"
  ok "pi already installed: $PI_VER ($PI_BIN)"
else
  info "Installing pi…"
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent || {
    err "npm install failed – try the curl installer:"
    echo "  curl -fsSL https://pi.dev/install.sh | sh"
    exit 1
  }
  # Try to find it again
  for candidate in "$HOME/.local/node-v22/bin/pi" "/usr/local/bin/pi"; do
    if [[ -x "$candidate" ]]; then
      PI_BIN="$candidate"
      break
    fi
  done
  if [[ -z "$PI_BIN" ]]; then
    PI_BIN="$(command -v pi 2>/dev/null || true)"
  fi
  ok "pi installed"
fi

# ── Step 3: Install Pi packages (extensions & skills) ────────────────
header "Step 3 – Install extensions & skills"

if [[ -z "$PI_BIN" ]]; then
  err "Cannot install packages – pi binary not found"
else
  declare -a PKGS=(
    "npm:pi-agent-browser-native"
    "npm:pi-agent-memory"
    "npm:pi-prompt-autoresearch"
    "npm:pi-web-access"
    "npm:pi-mcporter"
  )

  info "Installing packages (this may take a moment)…"
  for pkg in "${PKGS[@]}"; do
    info "  $pkg"
    "$PI_BIN" install "$pkg" 2>&1 | tail -1 || warn "  $pkg install had warnings"
  done
  ok "packages installed"
fi

# ── Step 4: Environment config ───────────────────────────────────────
header "Step 4 – Environment config"

if [[ -f "$ENV_FILE" ]]; then
  ok ".env.pi already exists"
  # Quick validation
  if grep -q "replace-me" "$ENV_FILE" 2>/dev/null; then
    warn ".env.pi still contains placeholder values – update before running"
  fi
else
  info "Creating .env.pi from template…"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  warn ".env.pi created from template – edit it with your Azure values:"
  echo ""
  echo "  $ENV_FILE"
  echo ""
  echo "Required: AZURE_OPENAI_API_KEY, AZURE_OPENAI_BASE_URL, PI_DEFAULT_MODEL"
fi

# ── Summary ──────────────────────────────────────────────────────────
header "Setup complete"

if [[ -z "$PI_BIN" ]]; then
  echo ""
  warn "Pi binary could not be located – try closing and reopening your terminal"
else
  echo ""
  info "Quick start:"
  echo ""
  echo "  1. Edit .env.pi with your Azure credentials:"
  echo "     \$EDITOR .env.pi"
  echo ""
  echo "  2. Run Pi:"
  echo "     ./scripts/run-pi.sh"
  echo "     # or"
  echo "     npm run pi"
  echo ""
fi