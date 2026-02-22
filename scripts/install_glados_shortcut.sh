#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT_DIR}/scripts/glados-ui"
BIN_DIR="${HOME}/.local/bin"

if [[ ! -x "$LAUNCHER" ]]; then
  echo "launcher not found or not executable: $LAUNCHER" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"
ln -sfn "$LAUNCHER" "${BIN_DIR}/glados"
ln -sfn "$LAUNCHER" "${BIN_DIR}/glados-ui"

echo "Installed shortcuts:"
echo "  ${BIN_DIR}/glados -> ${LAUNCHER}"
echo "  ${BIN_DIR}/glados-ui -> ${LAUNCHER}"
echo "Use from rb1-admin shell:"
echo "  glados"
