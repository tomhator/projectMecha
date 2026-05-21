#!/usr/bin/env bash
set -u

if bash Scripts/Validation/validate.sh >&2; then
  echo '{}'
else
  echo '{"permissionDecision":"deny","message":"Project validation failed. Run bash Scripts/Validation/validate.sh for details."}'
fi
