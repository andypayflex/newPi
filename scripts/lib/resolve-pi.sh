#!/usr/bin/env bash

resolve_pi_bin() {
  local candidate=""
  local wrapper="${HOME}/.local/bin/pi"

  if [[ -n "${PI_REAL_BIN:-}" && -x "${PI_REAL_BIN}" ]]; then
    printf '%s\n' "${PI_REAL_BIN}"
    return 0
  fi

  for candidate in \
    "${HOME}/.local/node-v22/bin/pi" \
    "${HOME}/.local/node-v22.22.3/bin/pi" \
    "/usr/local/bin/pi" \
    "/usr/bin/pi"
  do
    if [[ -x "${candidate}" && "${candidate}" != "${wrapper}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  candidate="$(command -v pi 2>/dev/null || true)"
  if [[ -n "${candidate}" && "${candidate}" != "${wrapper}" ]]; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  echo "Unable to locate the real Pi binary. Set PI_REAL_BIN to the installed executable path." >&2
  return 1
}
