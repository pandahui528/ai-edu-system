#!/bin/bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$(git rev-parse --git-path hooks)"

mkdir -p "$HOOKS_DIR"
cp "$ROOT/scripts/git-hooks/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "Git hooks installed to $HOOKS_DIR"
