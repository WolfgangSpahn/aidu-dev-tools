#!/usr/bin/env bash
set -euo pipefail

echo "Closing VS Code..."
pkill -f code || true

echo "Removing Codex VS Code extension state..."
rm -rf ~/.config/Code/User/globalStorage/*codex*
rm -rf ~/.config/Code/User/workspaceStorage/*/*codex*

if [[ -d "$HOME/.codex" ]]; then
  echo "Removing Codex auth/session files..."
  rm -f ~/.codex/auth.json
  rm -f ~/.codex/session.json
else
  echo "No ~/.codex directory found."
fi

echo "Done. Restart VS Code and sign in to Codex again."