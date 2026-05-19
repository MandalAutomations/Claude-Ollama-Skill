#!/usr/bin/env bash
# Extract structured data from stdin via Ollama.
#
# Usage:
#   cat file | extract.sh "all unique IP addresses, one per line"
#   cat file | extract.sh "every line containing ERROR or stack trace"

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: extract.sh \"description of what to extract\"" >&2
  exit 2
fi

WHAT="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ -t 0 ]]; then
  echo "extract.sh expects input on stdin" >&2
  exit 2
fi

"$HERE/ollama-call.sh" \
  --system "You extract data from text. Output only the extracted items, one per line. No headings, no explanations, no markdown fences." \
  --prompt "Extract: $WHAT"
