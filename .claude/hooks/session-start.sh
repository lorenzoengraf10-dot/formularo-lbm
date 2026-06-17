#!/bin/bash
# SessionStart hook — Claude Code on the web only.
#
# Re-installs ephemeral tools and restores the claude-mem database from
# the in-repo backup so memories survive container recycles.

set -uo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

{
  echo "[session-start] Bootstrapping persistent tools..."

  # 1) Restore claude-mem database before installing, so the plugin picks it up.
  BACKUP_DB="${CLAUDE_PROJECT_DIR}/.claude/mem-backup/claude-mem.db"
  MEM_DIR="${HOME}/.claude-mem"
  if [ -f "$BACKUP_DB" ]; then
    mkdir -p "$MEM_DIR"
    cp "$BACKUP_DB" "$MEM_DIR/claude-mem.db"
    echo "[session-start] claude-mem.db restored from repo backup"
  else
    echo "[session-start] No backup found — fresh start for claude-mem"
  fi

  # 2) Remotion best-practices skill (global scope).
  if npx -y skills add remotion-dev/skills --global -y; then
    echo "[session-start] remotion-dev/skills installed OK"
  else
    echo "[session-start] WARNING: remotion-dev/skills install failed (continuing)"
  fi

  # 3) claude-mem plugin.
  if npx -y claude-mem install; then
    echo "[session-start] claude-mem installed OK"
  else
    echo "[session-start] WARNING: claude-mem install failed (continuing)"
  fi

  # 4) Start claude-mem worker in background.
  npx claude-mem start &>/dev/null &
  echo "[session-start] claude-mem worker started (PID $!)"

  echo "[session-start] Done."
} >&2

exit 0
