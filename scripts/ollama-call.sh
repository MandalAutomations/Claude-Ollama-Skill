#!/usr/bin/env bash
# Generic Ollama wrapper. Reads input on stdin (optional), writes completion to stdout.
#
# Usage:
#   echo "prompt" | ollama-call.sh
#   echo "input" | ollama-call.sh --system "You are X" --prompt "Do Y to the input"
#   ollama-call.sh --prompt "no-stdin prompt"
#
# Env:
#   OLLAMA_MODEL   model name (default: tinyllama)
#   OLLAMA_HOST    base URL    (default: http://localhost:11434)

set -euo pipefail

MODEL="${OLLAMA_MODEL:-tinyllama}"
HOST="${OLLAMA_HOST:-http://localhost:11434}"
SYSTEM=""
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) SYSTEM="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --model)  MODEL="$2";  shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *)
      echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

STDIN_INPUT=""
if [[ ! -t 0 ]]; then
  STDIN_INPUT="$(cat)"
fi

# Build the full prompt: stdin gets appended after the explicit prompt.
FULL_PROMPT=""
if [[ -n "$PROMPT" && -n "$STDIN_INPUT" ]]; then
  FULL_PROMPT="$PROMPT

---
$STDIN_INPUT"
elif [[ -n "$PROMPT" ]]; then
  FULL_PROMPT="$PROMPT"
elif [[ -n "$STDIN_INPUT" ]]; then
  FULL_PROMPT="$STDIN_INPUT"
else
  echo "no prompt and no stdin — nothing to do" >&2
  exit 2
fi

# Reachability check — fail fast with a useful message.
if ! curl -sf -m 2 "$HOST/api/tags" >/dev/null; then
  echo "ollama not reachable at $HOST" >&2
  exit 3
fi

PYBIN="${PYTHON:-python3}"
command -v "$PYBIN" >/dev/null || { echo "python3 not found; required for safe JSON encoding" >&2; exit 4; }

PAYLOAD=$(MODEL="$MODEL" SYSTEM="$SYSTEM" PROMPT="$FULL_PROMPT" "$PYBIN" -c '
import json, os
print(json.dumps({
    "model":  os.environ["MODEL"],
    "prompt": os.environ["PROMPT"],
    "system": os.environ["SYSTEM"],
    "stream": False,
}))')

curl -sf -m 120 "$HOST/api/generate" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" \
  | "$PYBIN" -c 'import json,sys; print(json.load(sys.stdin).get("response",""), end="")'
