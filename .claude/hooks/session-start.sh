#!/bin/bash
#
# SessionStart hook for Claude Code on the web.
#
# Claude Code on the web runs in an ephemeral container: the home directory
# (~/.claude, ~/.agents) is wiped every time the container is recycled, so
# anything installed there does NOT persist on its own. This hook re-installs
# the tools we want available in every session:
#
#   1. remotion-dev/skills  -> the "remotion-best-practices" skill (global)
#   2. claude-mem           -> persistent memory plugin (~/.claude/plugins)
#
# Note: the Remotion skill is also committed to this repo under
# .claude/skills (project scope), so it works even if the network install
# below fails. This hook additionally installs it globally so it is available
# across projects.
#
# Runs synchronously on purpose: Claude loads skills and plugins at session
# start, so they must be installed BEFORE the session begins to be usable.

set -uo pipefail

# Only run in Claude Code on the web. Locally these tools persist across
# sessions, so re-installing on every start is unnecessary.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Send all install logs to stderr so they don't get injected into the session
# context as SessionStart stdout.
{
  echo "[session-start] Installing persistent tools for Claude Code on the web..."

  # 1) Remotion best-practices skill (global / user scope).
  if npx -y skills add remotion-dev/skills --global -y; then
    echo "[session-start] remotion-dev/skills installed OK"
  else
    echo "[session-start] WARNING: failed to install remotion-dev/skills (continuing)"
  fi

  # 2) claude-mem persistent memory plugin.
  if npx -y claude-mem install; then
    echo "[session-start] claude-mem installed OK"
  else
    echo "[session-start] WARNING: failed to install claude-mem (continuing)"
  fi

  echo "[session-start] Done."
} >&2

exit 0
