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
PROFILE="${SMOKE_PROFILE:-}"
MODE="${SMOKE_MODE:-contract}"
CONTRACT_FILE="${CONTRACT_FILE:-api-contract.md}"
echo "API_BASE=$BASE_URL"
echo "SMOKE_PROFILE=$PROFILE"
echo "SMOKE_MODE=$MODE"

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

contract_required_endpoints() {
  if [ ! -f "$CONTRACT_FILE" ]; then
    fail "Contract file not found: $CONTRACT_FILE"
  fi
  awk '
    /^## (GET|POST|PUT|DELETE) / {method=$2; path=$3; want=1; next}
    want && /^[[:space:]]*\+?@smoke:[[:space:]]*required/ {print method " " path; want=0; next}
    want && /^[[:space:]]*\+?@smoke:[[:space:]]*(optional|later)/ {want=0; next}
    want {want=0}
  ' "$CONTRACT_FILE"
}

contract_request() {
  local method="$1"
  local path="$2"
  local url_path="$path"
  url_path="${url_path//:jobId/job_123}"

  local body=""
  if [ "$method" = "POST" ] || [ "$method" = "PUT" ] || [ "$method" = "DELETE" ]; then
    if [ "$path" = "/upload/credential" ]; then
      body='{"contentType":"image/jpeg","size":12345,"sha256":"test"}'
    elif [ "$path" = "/jobs/analyze" ]; then
      body='{"input":{"type":"image","cosKey":"uploads/placeholder.jpg"},"options":{"mode":"extract_template_info"}}'
    else
      body='{}'
    fi
    resp="$(curl -sS -X "$method" -H 'Content-Type: application/json' -d "$body" -w "\n%{http_code}" "$BASE_URL$url_path")"
  else
    resp="$(curl -sS -X "$method" -w "\n%{http_code}" "$BASE_URL$url_path")"
  fi

  body_text="$(echo "$resp" | sed '$d')"
  code="$(echo "$resp" | tail -n 1)"
  echo "$body_text"
  print_trace "$body_text"

  if echo "$body_text" | grep -q "INVALID_PATH"; then
    fail "$method $path INVALID_PATH"
  fi
  if [ "$code" = "404" ]; then
    fail "$method $path status 404"
  fi
  if [ "$code" -lt 200 ] || [ "$code" -ge 300 ]; then
    fail "$method $path status $code"
  fi
}

run_profile() {
  local p="$1"
  case "$p" in
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
      echo "Unknown SMOKE_PROFILE=$p"
      exit 2
      ;;
  esac
}

if [ -n "$PROFILE" ]; then
  run_profile "$PROFILE"
  exit 0
fi

required_list="$(contract_required_endpoints)"
if [ -z "$required_list" ]; then
  echo "No required endpoints found in $CONTRACT_FILE"
  exit 0
fi

echo "Required endpoints:"
echo "$required_list"

while IFS= read -r line; do
  [ -z "$line" ] && continue
  method="$(echo "$line" | awk '{print $1}')"
  path="$(echo "$line" | awk '{print $2}')"
  contract_request "$method" "$path"
done <<< "$required_list"
