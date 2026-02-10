#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ROOT" ]; then
  echo "AUTO-TRIGGER: not a git repo"
  exit 1
fi
cd "$ROOT"

MODE="${AUTO_TRIGGER_MODE:-advice}"
NOW="$(date +"%Y%m%d-%H%M%S")"
DISPATCH_DIR="$ROOT/system-assets/dispatch"
DISPATCH_PATH="$DISPATCH_DIR/dispatch-$NOW.md"

mkdir -p "$DISPATCH_DIR"

OUTPUT=""
STATUS=0
if [ -n "${API_BASE:-}" ]; then
  OUTPUT="$({ API_BASE="$API_BASE" bash scripts/system-check.sh; } 2>&1)" || STATUS=$?
else
  OUTPUT="$({ bash scripts/system-check.sh; } 2>&1)" || STATUS=$?
fi

echo "$OUTPUT"

REPORT_PATH="$(echo "$OUTPUT" | awk -F= '/^SYSTEM_CHECK_REPORT=/ {print $2; exit}')"
if [ -z "$REPORT_PATH" ]; then
  REPORT_PATH="$(ls -t "$ROOT"/system-assets/reports/system-check-*.md 2>/dev/null | head -n 1 || true)"
fi

if [ "$STATUS" -eq 0 ]; then
  echo "AUTO-TRIGGER: no action (PASS)"
  exit 0
fi

FAIL_LINES=""
if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ]; then
  FAIL_LINES="$(grep -n "FAIL:" "$REPORT_PATH" | sed -E 's/^[0-9]+:[[:space:]]*//; s/^[[:space:]]*(-[[:space:]]*)+//' | grep -E '^FAIL:' | head -n 20)"
fi

ROUTED_OWNER=""
ROUTED_REASON=""
ROUTING_MATCH=""

RULE_MATCHED=0
ENG_MATCHED=0

# Rule/spec violations -> AI Tech Lead (highest priority)
if echo "$FAIL_LINES" | grep -E "FAIL: Global system:|FAIL: System spec:|FAIL: Operating rules:|FAIL: Ownership" >/dev/null 2>&1; then
  RULE_MATCHED=1
fi

# Engineering/tooling failures -> AI Engineering Reliability
if echo "$FAIL_LINES" | grep -E "FAIL: Smoke:|FAIL: Contracts:|FAIL: Repo sanity:" >/dev/null 2>&1; then
  ENG_MATCHED=1
fi
if echo "$FAIL_LINES" | grep -E "awk|curl|chmod|permission|INVALID_PATH|INVALID_ENV" >/dev/null 2>&1; then
  ENG_MATCHED=1
fi

if [ "$RULE_MATCHED" -eq 1 ]; then
  ROUTED_OWNER="AI Tech Lead"
  ROUTED_REASON="rule/spec violation detected"
  ROUTING_MATCH="rule/spec"
elif [ "$ENG_MATCHED" -eq 1 ]; then
  ROUTED_OWNER="AI Engineering Reliability"
  ROUTED_REASON="tooling/environment error detected"
  ROUTING_MATCH="tooling/env"
else
  ROUTED_OWNER="AI Engineering Reliability"
  ROUTED_REASON="unclassified failure; default routing"
  ROUTING_MATCH="default"
fi

if [ "${AUTO_TRIGGER_DEBUG:-}" = "1" ]; then
  echo "AUTO_TRIGGER_DEBUG: fail_lines (normalized)"
  if [ -n "$FAIL_LINES" ]; then
    echo "$FAIL_LINES"
  else
    echo "(none)"
  fi
  echo "AUTO_TRIGGER_DEBUG: matched=$ROUTING_MATCH"
  echo "AUTO_TRIGGER_DEBUG: owner=$ROUTED_OWNER"
fi

ALSO_NOTIFY=""
PREV_REPORT="$(ls -t "$ROOT"/system-assets/reports/system-check-*.md 2>/dev/null | sed -n '2p')"
if [ -n "$PREV_REPORT" ] && [ -f "$PREV_REPORT" ] && [ -n "$FAIL_LINES" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if grep -F "$line" "$PREV_REPORT" >/dev/null 2>&1; then
      ALSO_NOTIFY="Also notify Global Retrospective"
      break
    fi
  done <<< "$FAIL_LINES"
fi

SUGGESTED_CMD="bash scripts/system-check.sh"
if [ -n "${API_BASE:-}" ]; then
  SUGGESTED_CMD="API_BASE=$API_BASE bash scripts/system-check.sh"
fi
if [ "$ROUTED_OWNER" = "AI Tech Lead" ]; then
  SUGGESTED_CMD="编辑 system-spec/global-system.md 修复缺失关键字后，再运行 bash scripts/system-check.sh"
fi

GUARDRAILS="- 必须遵守 File Ownership & Write Boundaries\n- 必须遵守 Failure Routing\n- 不得越权处理"

{
  echo "# Dispatch Ticket"
  echo
  echo "## Summary"
  echo "- Trigger: system-check FAIL"
  echo "- Routed owner: $ROUTED_OWNER"
  echo "- Reason: $ROUTED_REASON"
  echo
  echo "## Evidence"
  echo "- Report: ${REPORT_PATH:-unknown}"
  echo "- Fail lines:"
  if [ -n "$FAIL_LINES" ]; then
    echo "$FAIL_LINES" | sed 's/^/- /'
  else
    echo "- (no FAIL lines captured)"
  fi
  if [ -n "$ALSO_NOTIFY" ]; then
    echo "- $ALSO_NOTIFY"
  fi
  echo
  echo "## Routed Owner"
  echo "- $ROUTED_OWNER"
  echo
  echo "## Suggested Next Command"
  echo "- $SUGGESTED_CMD"
  echo
  echo "## Guardrails"
  echo -e "$GUARDRAILS"
  echo
  echo "## Optional Human Escalation"
  echo "- 仅方向/战略/成本相关时升级 Human"
} > "$DISPATCH_PATH"

echo "AUTO-TRIGGER: dispatch generated: $DISPATCH_PATH"
if [ "$MODE" = "strict" ]; then
  echo "AUTO-TRIGGER: BLOCKED (strict mode)"
  exit 1
fi

exit "$STATUS"
