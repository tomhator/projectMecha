#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 1

failed=0

check_pattern() {
  local label="$1"
  local pattern="$2"
  local matches

  matches="$(find . \
    -path './.git' -prune -o \
    -path './.godot' -prune -o \
    -name '*.gd' -type f -print0 |
    xargs -0 grep -nE "$pattern" 2>/dev/null || true)"

  if [ -n "$matches" ]; then
    echo "FAIL godot4-pattern: $label"
    echo "$matches"
    failed=1
  fi
}

check_pattern "Use @onready var instead of onready var" '^[[:space:]]*onready[[:space:]]+var[[:space:]]'
check_pattern "Use @export var instead of export var" '^[[:space:]]*export[[:space:]]+var[[:space:]]'
check_pattern "Use await instead of yield()" 'yield[[:space:]]*\('
check_pattern "Use Time.get_ticks_msec() instead of OS.get_ticks_msec()" 'OS\.get_ticks_msec[[:space:]]*\('
check_pattern "Use signal.connect(method) instead of Godot 3 connect signature" '\.connect[[:space:]]*\([[:space:]]*"[^"]+"[[:space:]]*,[[:space:]]*[^,]+[[:space:]]*,[[:space:]]*"[^"]+"'

if [ "$failed" -eq 0 ]; then
  echo "OK godot4 syntax patterns"
fi

exit "$failed"
