#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 1

failed=0
today="${PROJECT_MECHA_DATE:-$(date +%F)}"
worknote_path="Docs/WorkNote/${today}.md"

require_file() {
  local path="$1"
  local label="$2"

  if [ ! -f "$path" ]; then
    echo "FAIL docs: missing $label ($path)"
    failed=1
  else
    echo "OK docs: $label"
  fi
}

require_file "ARCHITECTURE.md" "architecture document"
require_file "Docs/TODO/TODO-NEXT.md" "active TODO backlog"
require_file "$worknote_path" "today worknote"

exit "$failed"
