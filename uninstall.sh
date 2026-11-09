#!/usr/bin/env bash
# Atajo para desinstalar: ./uninstall.sh [opciones]
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/install.sh" uninstall "$@"
