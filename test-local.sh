#!/usr/bin/env bash
# test-local.sh — Run the AI Dev Agent locally against a target repo.
# Does NOT require Jira credentials. Uses ticket.json from this directory.
# Usage: ./test-local.sh [/path/to/target-repo]

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

info()    { echo -e "${GREEN}[agent]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $*"; }
err()     { echo -e "${RED}[error]${NC} $*" >&2; }

# ── Pre-flight checks ─────────────────────────────────────────────────────────
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  err "ANTHROPIC_API_KEY is not set."
  echo ""
  echo "  Export it first:"
  echo "    export ANTHROPIC_API_KEY=sk-ant-..."
  echo ""
  exit 1
fi

if ! command -v claude &>/dev/null; then
  err "'claude' is not installed or not on PATH."
  echo ""
  echo "  Install Claude Code:"
  echo "    npm install -g @anthropic-ai/claude-code"
  echo ""
  exit 1
fi

# ── Locate files ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICKET_JSON="$SCRIPT_DIR/ticket.json"
AGENT_PROMPT="$SCRIPT_DIR/agent-prompt.md"

if [ ! -f "$TICKET_JSON" ]; then
  err "ticket.json not found at $TICKET_JSON"
  exit 1
fi

if [ ! -f "$AGENT_PROMPT" ]; then
  err "agent-prompt.md not found at $AGENT_PROMPT"
  exit 1
fi

# ── Target repo ───────────────────────────────────────────────────────────────
TARGET_REPO="${1:-}"

if [ -z "$TARGET_REPO" ]; then
  # Default: look for test-repo next to this script
  TARGET_REPO="$SCRIPT_DIR/test-repo"

  if [ ! -d "$TARGET_REPO" ]; then
    warn "No target repo specified and $TARGET_REPO does not exist."
    echo ""
    echo "  Creating a minimal test-repo for you..."
    bash "$SCRIPT_DIR/create-test-repo.sh"
    echo ""
  fi
fi

if [ ! -d "$TARGET_REPO" ]; then
  err "Target repo not found: $TARGET_REPO"
  echo "  Pass a path as the first argument:  ./test-local.sh /path/to/repo"
  exit 1
fi

# ── Copy ticket.json into the target repo ─────────────────────────────────────
cp "$TICKET_JSON" "$TARGET_REPO/ticket.json"

# ── Extract ticket info for display ──────────────────────────────────────────
TICKET_KEY=$(python3 -c "import json; d=json.load(open('$TICKET_JSON')); print(d['key'])" 2>/dev/null || echo "UNKNOWN")
TICKET_SUMMARY=$(python3 -c "import json; d=json.load(open('$TICKET_JSON')); print(d['fields']['summary'])" 2>/dev/null || echo "(could not parse)")

# ── Run ───────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════"
info "AI Dev Agent — Local Test Run"
echo "  Ticket:  $TICKET_KEY"
echo "  Summary: $TICKET_SUMMARY"
echo "  Repo:    $TARGET_REPO"
echo "  Prompt:  $AGENT_PROMPT"
echo "═══════════════════════════════════════════════════════════"
echo ""

cd "$TARGET_REPO"

claude \
  --system-prompt "$(cat "$AGENT_PROMPT")" \
  --max-turns 20 \
  --dangerously-skip-permissions \
  "Implement the Jira ticket described in ticket.json. Follow the workflow in the system prompt exactly."

EXIT_CODE=$?

echo ""
echo "═══════════════════════════════════════════════════════════"
if [ $EXIT_CODE -eq 0 ]; then
  info "Agent run complete. Check the repo for changes:"
  echo "  cd $TARGET_REPO && git log --oneline -5"
else
  err "Agent exited with code $EXIT_CODE"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""

exit $EXIT_CODE
