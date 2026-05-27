#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 1

GDPARSE_BIN="${GDPARSE_BIN:-}"
GODOT_BIN="${GODOT_BIN:-}"
failed=0

run_check() {
  local label="$1"
  shift

  echo "==> $label"
  if "$@"; then
    echo "PASS $label"
  else
    echo "FAIL $label"
    failed=1
  fi
}

run_godot_checked() {
  local bin="$1"
  shift
  local output
  local status

  output="$("$bin" "$@" 2>&1)"
  status=$?
  printf '%s\n' "$output"

  if [ "$status" -ne 0 ]; then
    return "$status"
  fi

  if printf '%s\n' "$output" | grep -E '^(SCRIPT ERROR|ERROR):' >/dev/null 2>&1; then
    return 1
  fi

  return 0
}

find_godot_bin() {
  if [ -n "$GODOT_BIN" ]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi

  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return 0
  fi

  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4
    return 0
  fi

  for candidate in \
    "$HOME/Desktop/고도/Godot.app/Contents/MacOS/Godot" \
    "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" \
    "${USERPROFILE:-}/gameDev/Godot_v4.6.2-stable_win64.exe" \
    "C:/Users/theoe/gameDev/Godot_v4.6.2-stable_win64.exe" \
    "${USERPROFILE:-}/Downloads/Godot_v4.6.1-stable_win64.exe" \
    "${USERPROFILE:-}/Desktop/Godot_v4.6.1-stable_win64.exe" \
    "C:/Godot/Godot_v4.6.1-stable_win64.exe" \
    "C:/Program Files/Godot/Godot_v4.6.1-stable_win64.exe"
  do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

find_gdparse_bin() {
  if [ -n "$GDPARSE_BIN" ]; then
    printf '%s\n' "$GDPARSE_BIN"
    return 0
  fi

  if command -v gdparse >/dev/null 2>&1; then
    command -v gdparse
    return 0
  fi

  for candidate in \
    "$HOME/Library/Python/3.9/bin/gdparse" \
    "$HOME/.local/bin/gdparse" \
    "${APPDATA:-}/Python/Python39/Scripts/gdparse.exe" \
    "${LOCALAPPDATA:-}/Programs/Python/Python39/Scripts/gdparse.exe"
  do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

run_gdparse() {
  local bin

  if ! bin="$(find_gdparse_bin)"; then
    echo "SKIP gdparse: command not found (set GDPARSE_BIN to override)"
    return 0
  fi

  find . \
    -path './.git' -prune -o \
    -path './.godot' -prune -o \
    -name '*.gd' -type f -print0 |
    xargs -0 "$bin"
}

run_godot_headless() {
  local bin

  if ! bin="$(find_godot_bin)"; then
    echo "SKIP godot headless: command not found (set GODOT_BIN to override)"
    return 0
  fi

  run_godot_checked "$bin" --headless --path . --quit
}

run_godot_script() {
  local script_path="$1"
  local bin

  if ! bin="$(find_godot_bin)"; then
    echo "SKIP godot script: command not found (set GODOT_BIN to override)"
    return 0
  fi

  run_godot_checked "$bin" --headless --path . --script "$script_path"
}

run_check "Godot 4 syntax pattern scan" bash Scripts/Validation/check_godot4_syntax_patterns.sh
run_check "Project docs check" bash Scripts/Validation/check_project_docs.sh
run_check "GDScript parser" run_gdparse
run_check "Godot headless project load" run_godot_headless
run_check "Resource integrity" run_godot_script res://Scripts/Validation/check_resource_integrity.gd
run_check "Scene smoke" run_godot_script res://Scripts/Validation/check_scene_smoke.gd
run_check "Base state contracts" run_godot_script res://Scripts/Validation/check_base_state.gd
run_check "CoreSelect layout" run_godot_script res://Scripts/Validation/check_core_select_layout.gd
run_check "Current work contracts" run_godot_script res://Scripts/Validation/check_current_work_contracts.gd
run_check "P0 combat flows" run_godot_script res://Scripts/Validation/check_p0_combat_flows.gd

if [ "$failed" -eq 0 ]; then
  echo "Validation complete: PASS"
else
  echo "Validation complete: FAIL"
fi

exit "$failed"
