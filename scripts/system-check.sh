#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
NOW="$(date +"%Y%m%d-%H%M%S")"
REPORT_DIR="$ROOT/system-assets/reports"
REPORT_PATH="$REPORT_DIR/system-check-$NOW.md"
SMOKE_PROFILE_DEFAULT="health-only"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

RESULTS=()
AGENTS_LIST=""

print_result() {
  local status="$1"
  local label="$2"
  RESULTS+=("$status|$label")
  printf "%s - %s\n" "$status" "$label"
  case "$status" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    WARNING) WARN_COUNT=$((WARN_COUNT + 1)) ;;
  esac
}

ensure_report_dir() {
  mkdir -p "$REPORT_DIR"
}

repo_sanity() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_result PASS "Repo sanity: git repo"
  else
    print_result FAIL "Repo sanity: not a git repo"
  fi

  local dirs=(agents scripts system-spec smoke-tests)
  for d in "${dirs[@]}"; do
    if [ -d "$ROOT/$d" ]; then
      print_result PASS "Repo sanity: $d exists"
    else
      print_result FAIL "Repo sanity: $d missing"
    fi
  done

  if [ -d "$ROOT/system-assets" ]; then
    print_result PASS "Repo sanity: system-assets exists"
  else
    print_result FAIL "Repo sanity: system-assets missing"
  fi

  if [ -d "$ROOT/contracts" ]; then
    print_result WARNING "Repo sanity: contracts/ exists (unexpected location)"
  else
    print_result WARNING "Repo sanity: contracts/ missing (ok if not used)"
  fi
}

agent_presence() {
  local required=(
    "agents/03_tech-cto.md"
    "agents/04_user-validation.md"
    "agents/05_global-retrospective.md"
    "agents/06_engineering-reliability.md"
  )
  local all_present=1
  for f in "${required[@]}"; do
    if [ -f "$ROOT/$f" ]; then
      print_result PASS "Agent presence: $f"
    else
      print_result FAIL "Agent presence: $f missing"
      all_present=0
    fi
  done

  AGENTS_LIST="$(ls -1 "$ROOT/agents"/*.md 2>/dev/null | sed "s|$ROOT/||" | tr "\n" ",")"
  print_result PASS "Agent list captured"
}

system_spec_checks() {
  if [ -f "$ROOT/system-spec/global-system.md" ]; then
    print_result PASS "System spec: global-system.md exists"
  else
    print_result FAIL "System spec: global-system.md missing"
  fi

  if [ -f "$ROOT/system-spec/operating-rules.md" ]; then
    print_result PASS "System spec: operating-rules.md exists"
  else
    print_result FAIL "System spec: operating-rules.md missing"
  fi

  local op="$ROOT/system-spec/operating-rules.md"
  if [ -f "$op" ]; then
    grep -E "AI 管理层|AI Management Layer" "$op" >/dev/null && print_result PASS "Operating rules: AI 管理层" || print_result FAIL "Operating rules: AI 管理层 missing"
    grep -E "AI 执行层|AI Execution Layer" "$op" >/dev/null && print_result PASS "Operating rules: AI 执行层" || print_result FAIL "Operating rules: AI 执行层 missing"
    grep -E "Out-of-Band|系统进化角色|Global Retrospective" "$op" >/dev/null && print_result PASS "Operating rules: 系统进化角色" || print_result FAIL "Operating rules: 系统进化角色 missing"
    grep -E "Failure Routing|失败路由" "$op" >/dev/null && print_result PASS "Operating rules: Failure Routing" || print_result FAIL "Operating rules: Failure Routing missing"
  fi

  local gs="$ROOT/system-spec/global-system.md"
  if [ -f "$gs" ]; then
    grep -E "AI Tech Lead" "$gs" >/dev/null && print_result PASS "Global system: AI Tech Lead" || print_result FAIL "Global system: AI Tech Lead missing"
    grep -E "AI QA Engineer" "$gs" >/dev/null && print_result PASS "Global system: AI QA Engineer" || print_result FAIL "Global system: AI QA Engineer missing"
    grep -E "AI Engineering Reliability" "$gs" >/dev/null && print_result PASS "Global system: AI Engineering Reliability" || print_result FAIL "Global system: AI Engineering Reliability missing"
    grep -E "市场与验证|Market" "$gs" >/dev/null && print_result PASS "Global system: Market" || print_result FAIL "Global system: Market missing"
    grep -E "Global Retrospective|复盘" "$gs" >/dev/null && print_result PASS "Global system: Global Retrospective" || print_result FAIL "Global system: Global Retrospective missing"
  fi
}

contracts_checks() {
  local contract="$ROOT/system-assets/contracts/api-contract.md"
  if [ ! -f "$contract" ]; then
    contract="$ROOT/api-contract.md"
  fi
  if [ -f "$contract" ]; then
    print_result PASS "Contracts: api-contract.md found"
  else
    print_result FAIL "Contracts: api-contract.md missing"
    return
  fi

  local count
  count=$(grep -E "^[[:space:]]*(##+|[-*])?[[:space:]]*(GET|POST|PUT|DELETE)[[:space:]]+/" "$contract" | wc -l | tr -d " ")
  if [ "$count" -gt 0 ]; then
    print_result PASS "Contracts: endpoint headers found ($count)"
  else
    print_result FAIL "Contracts: no endpoint headers found"
  fi
}

smoke_tests() {
  local smoke="$ROOT/smoke-tests/smoke.curl.sh"
  if [ ! -f "$smoke" ]; then
    print_result FAIL "Smoke: smoke.curl.sh missing"
    return
  fi

  if [ ! -x "$smoke" ]; then
    chmod +x "$smoke" 2>/dev/null || true
    print_result WARNING "Smoke: smoke.curl.sh was not executable; chmod attempted"
  else
    print_result PASS "Smoke: smoke.curl.sh executable"
  fi

  if [ -n "${API_BASE:-}" ]; then
    local profile="${SMOKE_PROFILE:-$SMOKE_PROFILE_DEFAULT}"
    if API_BASE="$API_BASE" SMOKE_PROFILE="$profile" bash "$smoke"; then
      print_result PASS "Smoke: online run"
    else
      print_result FAIL "Smoke: online run failed"
    fi
  else
    local out
    out="$({ bash "$smoke"; } 2>&1)" || true
    echo "$out" | grep -E "API_BASE is required" >/dev/null && print_result PASS "Smoke: offline check" || print_result FAIL "Smoke: offline check failed"
  fi
}

ownership_hints() {
  local hit=0
  if grep -E "ownership|只读|禁止修改" "$ROOT/system-spec/operating-rules.md" >/dev/null 2>&1; then
    hit=1
  fi
  if grep -R -E "ownership|只读|禁止修改" "$ROOT/system-assets" >/dev/null 2>&1; then
    hit=1
  fi
  if [ "$hit" -eq 1 ]; then
    print_result PASS "Ownership boundary hints present"
  else
    print_result WARNING "Ownership boundary hints missing"
  fi
}

write_report() {
  ensure_report_dir
  local branch
  local commit
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  commit="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

  {
    echo "# System Check Report"
    echo
    echo "## Summary"
    echo "- Overall: $( [ "$FAIL_COUNT" -gt 0 ] && echo FAIL || echo PASS )"
    echo "- Date: $NOW"
    echo "- Branch: $branch"
    echo "- Commit: $commit"
    echo "- API_BASE: ${API_BASE:-}" 
    echo "- SMOKE_PROFILE: ${SMOKE_PROFILE:-$SMOKE_PROFILE_DEFAULT}"
    echo
    echo "## Checks"
    for r in "${RESULTS[@]}"; do
      echo "- ${r%%|*}: ${r#*|}"
    done
    echo
    echo "## Agents"
    echo "- ${AGENTS_LIST%,}"
    echo
    echo "## Notes"
    echo "- "
    echo
    echo "## Next actions"
    echo "- "
  } > "$REPORT_PATH"
}

main() {
  if [ -z "$ROOT" ]; then
    echo "FAIL - Repo sanity: not a git repo"
    exit 1
  fi

  repo_sanity
  agent_presence
  system_spec_checks
  contracts_checks
  smoke_tests
  ownership_hints
  write_report

  echo "Report: $REPORT_PATH"
  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Summary: FAIL"
    exit 1
  fi
  echo "Summary: PASS"
  exit 0
}

main
