#!/bin/zsh
set -euo pipefail

BASE_URL="${API_BASE_URL:-http://localhost:3000}"
MAX_POLL="${MAX_POLL:-5}"
SLEEP_SEC="${SLEEP_SEC:-2}"

log() { printf "%s\n" "$1"; }
fail() { log "FAIL: $1"; exit 1; }

log "==> health"
health_resp="$(curl -sS -w "\n%{http_code}" "$BASE_URL/health")"
health_body="$(echo "$health_resp" | sed '$d')"
health_code="$(echo "$health_resp" | tail -n 1)"
echo "$health_body"
[ "$health_code" = "200" ] || fail "/health status $health_code"

log "==> upload credential"
cred_resp="$(curl -sS -H 'Content-Type: application/json' -d '{"contentType":"image/jpeg","size":12345,"sha256":"test"}' \
  -w "\n%{http_code}" "$BASE_URL/upload/credential")"
cred_body="$(echo "$cred_resp" | sed '$d')"
cred_code="$(echo "$cred_resp" | tail -n 1)"
echo "$cred_body"
[ "$cred_code" = "200" ] || fail "/upload/credential status $cred_code"

log "==> analyze job"
job_resp="$(curl -sS -H 'Content-Type: application/json' -d '{"input":{"type":"image","cosKey":"uploads/placeholder.jpg"},"options":{"mode":"extract_template_info"}}' \
  -w "\n%{http_code}" "$BASE_URL/jobs/analyze")"
job_body="$(echo "$job_resp" | sed '$d')"
job_code="$(echo "$job_resp" | tail -n 1)"
echo "$job_body"
[ "$job_code" = "200" ] || fail "/jobs/analyze status $job_code"

job_id="$(echo "$job_body" | python - <<'PY'
import json,sys
try:
  data=json.load(sys.stdin).get("data",{})
  print(data.get("jobId",""))
except Exception:
  print("")
PY
)"

if [ -n "$job_id" ]; then
  log "==> polling job: $job_id"
  for i in $(seq 1 "$MAX_POLL"); do
    poll_resp="$(curl -sS -w "\n%{http_code}" "$BASE_URL/jobs/$job_id")"
    poll_body="$(echo "$poll_resp" | sed '$d')"
    poll_code="$(echo "$poll_resp" | tail -n 1)"
    echo "$poll_body"
    [ "$poll_code" = "200" ] || fail "/jobs/$job_id status $poll_code"
    status="$(echo "$poll_body" | python - <<'PY'
import json,sys
try:
  data=json.load(sys.stdin).get("data",{})
  print(data.get("status",""))
except Exception:
  print("")
PY
)"
    if [ "$status" = "done" ] || [ "$status" = "failed" ]; then
      log "job status: $status"
      exit 0
    fi
    sleep "$SLEEP_SEC"
  done
  fail "job not finished after $MAX_POLL polls"
fi

log "sync job done"
