#!/usr/bin/env bash
# Classify stdin into one of a comma-separated set of labels.
#
# Usage:
#   echo "fix: null check" | classify.sh "feat,fix,chore,docs,refactor"

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: classify.sh \"label1,label2,...\"" >&2
  exit 2
fi

LABELS="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ -t 0 ]]; then
  echo "classify.sh expects input on stdin" >&2
  exit 2
fi

"$HERE/ollama-call.sh" \
  --system "You are a strict classifier. Output exactly one label from the allowed set. No punctuation, no explanation, no quotes." \
  --prompt "Allowed labels: $LABELS

Classify the input into exactly one of those labels."
