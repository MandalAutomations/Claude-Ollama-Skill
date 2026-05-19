#!/usr/bin/env bash
# Summarize a file or stdin into N bullets via Ollama.
#
# Usage:
#   summarize.sh path/to/file [--lines N]
#   cat file | summarize.sh [--lines N]

set -euo pipefail

LINES=5
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lines) LINES="$2"; shift 2 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) FILE="$1"; shift ;;
  esac
done

HERE="$(cd "$(dirname "$0")" && pwd)"

INPUT=""
if [[ -n "$FILE" ]]; then
  [[ -r "$FILE" ]] || { echo "cannot read: $FILE" >&2; exit 2; }
  INPUT="$(cat "$FILE")"
elif [[ ! -t 0 ]]; then
  INPUT="$(cat)"
else
  echo "no file argument and no stdin" >&2
  exit 2
fi

# Cap input — tinyllama-class models lose the plot past ~2k tokens. Keep first/last
# slices so log-style content keeps its head and tail context.
MAX_CHARS=8000
LEN=${#INPUT}
if (( LEN > MAX_CHARS )); then
  HEAD_LEN=$(( MAX_CHARS / 2 ))
  TAIL_LEN=$(( MAX_CHARS - HEAD_LEN ))
  INPUT="${INPUT:0:$HEAD_LEN}

... [truncated $((LEN - MAX_CHARS)) chars] ...

${INPUT: -$TAIL_LEN}"
fi

printf '%s' "$INPUT" | "$HERE/ollama-call.sh" \
  --system "You produce terse factual summaries. No preamble, no commentary, just the bullets." \
  --prompt "Summarize the input below in exactly $LINES bullet points. Each bullet must be a single short sentence."
