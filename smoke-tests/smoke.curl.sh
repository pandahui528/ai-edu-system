#!/bin/bash
set -euo pipefail

if [ -z "${API_BASE:-}" ]; then
  echo "API_BASE is required. Example:"
  echo "API_BASE=https://your-api.example.com SMOKE_PROFILE=health-only bash smoke-tests/smoke.curl.sh"
  exit 2
fi

BASE_URL="${API_BASE}"
MAX_POLL="${MAX_POLL:-5}"
SLEEP_SEC="${SLEEP_SEC:-2}"
PROFILE="${SMOKE_PROFILE:-core-sync}"
echo "API_BASE=$BASE_URL"
echo "SMOKE_PROFILE=$PROFILE"

log() { printf "%s\n" "$1"; }
fail() { log "FAIL: $1"; exit 1; }

print_trace() {
  local body="$1"
  local tid
  tid="$(echo "$body" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get("traceId",""))' 2>/dev/null || true)"
  log "traceId: $tid"
}

health() {
  log "==> health"
  health_resp="$(curl -sS -w "\n%{http_code}" "$BASE_URL/health")"
  health_body="$(echo "$health_resp" | sed '$d')"
  health_code="$(echo "$health_resp" | tail -n 1)"
  echo "$health_body"
  print_trace "$health_body"
  [ "$health_code" = "200" ] || fail "/health status $health_code"
}

upload_credential() {
  log "==> upload credential"
  cred_resp="$(curl -sS -H 'Content-Type: application/json' -d '{"contentType":"image/jpeg","size":12345,"sha256":"test"}' -w "\n%{http_code}" "$BASE_URL/upload/credential")"
  cred_body="$(echo "$cred_resp" | sed '$d')"
  cred_code="$(echo "$cred_resp" | tail -n 1)"
  echo "$cred_body"
  print_trace "$cred_body"
  [ "$cred_code" = "200" ] || fail "/upload/credential status $cred_code"
}

jobs_analyze() {
  log "==> analyze job"
  job_resp="$(curl -sS -H 'Content-Type: application/json' -d '{"input":{"type":"image","cosKey":"uploads/placeholder.jpg"},"options":{"mode":"extract_template_info"}}' -w "\n%{http_code}" "$BASE_URL/jobs/analyze")"
  job_body="$(echo "$job_resp" | sed '$d')"
  job_code="$(echo "$job_resp" | tail -n 1)"
  echo "$job_body"
  print_trace "$job_body"
  [ "$job_code" = "200" ] || fail "/jobs/analyze status $job_code"
  job_id="$(echo "$job_body" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get("data",{}).get("jobId",""))' 2>/dev/null || true)"
}

jobs_poll() {
  if [ -z "${job_id:-}" ]; then
    fail "async mode expected jobId"
  fi
  log "==> polling job: $job_id"
  for i in $(seq 1 "$MAX_POLL"); do
    poll_resp="$(curl -sS -w "\n%{http_code}" "$BASE_URL/jobs/$job_id")"
    poll_body="$(echo "$poll_resp" | sed '$d')"
    poll_code="$(echo "$poll_resp" | tail -n 1)"
    echo "$poll_body"
    print_trace "$poll_body"
    [ "$poll_code" = "200" ] || fail "/jobs/$job_id status $poll_code"
    status="$(echo "$poll_body" | /usr/bin/python3 -c 'import json,sys;print(json.load(sys.stdin).get("data",{}).get("status",""))' 2>/dev/null || true)"
    if [ "$status" = "done" ] || [ "$status" = "failed" ]; then
      log "job status: $status"
      return
    fi
    sleep "$SLEEP_SEC"
  done
  fail "job not finished after $MAX_POLL polls"
}

case "$PROFILE" in
  health-only)
    health
    ;;
  core-sync)
    health
    jobs_analyze
    ;;
  upload+jobs)
    health
    upload_credential
    jobs_analyze
    jobs_poll
    ;;
  *)
    echo "Unknown SMOKE_PROFILE=$PROFILE"
    exit 2
    ;;
esac
