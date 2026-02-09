#!/bin/zsh
set -euo pipefail

REPO="/Users/peterpan528/ai-edu-system"
LOG="$HOME/Library/Logs/ai-edu-system-autosync.log"

log() {
  printf "%s %s\n" "$(date "+%Y-%m-%d %H:%M:%S")" "$1" >> "$LOG"
}

cd "$REPO" || { log "repo path not found"; exit 0; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "not a git repo"; exit 0; }

git fetch origin --quiet || { log "fetch failed"; exit 0; }

if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  log "no upstream configured"
  exit 0
fi

local_sha="$(git rev-parse @)"
remote_sha="$(git rev-parse @{u})"
base_sha="$(git merge-base @ @{u})"

if [ "$local_sha" = "$remote_sha" ]; then
  :
elif [ "$local_sha" = "$base_sha" ]; then
  if [ -z "$(git status --porcelain)" ]; then
    git pull --ff-only origin HEAD >/dev/null 2>&1 || { log "auto pull failed"; exit 0; }
  else
    log "behind remote with local changes; skip auto pull"
    exit 0
  fi
elif [ "$remote_sha" = "$base_sha" ]; then
  :
else
  log "diverged from remote; manual resolution required"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  ts="$(date "+%Y-%m-%d %H:%M:%S")"
  if git commit -m "chore: autosync $ts" >/dev/null 2>&1; then
    git push origin HEAD >/dev/null 2>&1 || log "push failed"
  else
    log "commit failed (missing user config?)"
  fi
fi
