---
name: ollama
description: Offload narrow, well-defined subtasks to a local Ollama model to save Anthropic tokens. Use for bulk summarization (logs, large files before the relevant section is found), simple classification, regex-style structured extraction, and other "cheap labor" steps where a small local model is good enough. Do NOT use for reasoning, coding, or anything where quality matters more than cost.
---

# Ollama offload skill

This skill teaches you to shell out to a local Ollama instance for the parts of a task that don't need Claude's intelligence. The goal is to reduce the number of tokens that flow into Claude's context.

## When to use Ollama

Use Ollama (via `scripts/ollama-call.sh` or the helpers in `scripts/`) when **all** of the following are true:

1. The subtask is mechanical or pattern-matching, not reasoning. Examples: "give me a 3-line summary of this log file", "extract every IP address from this text", "classify this commit message as feat/fix/chore".
2. The input is large enough that piping it into Claude's context would be wasteful (rule of thumb: more than ~200 lines or ~2000 tokens, AND you don't need every detail).
3. A wrong answer is recoverable — you can re-read the source yourself if the local model gets it wrong.

## When NOT to use Ollama

- Writing or editing code.
- Anything the user asked **you** (Claude) to do directly. They want your judgment, not tinyllama's.
- Security-sensitive parsing (auth tokens, secrets — don't pipe them through any model).
- Anything where a hallucinated answer would silently cause harm.

## Precheck

Before invoking, confirm Ollama is reachable and a model is available:

```bash
curl -sf -m 2 http://localhost:11434/api/tags >/dev/null && echo OK
```

If that fails, **don't fall back to running the same task in your own context** — tell the user Ollama isn't reachable and ask whether to proceed without it. Silent fallback defeats the whole point of the skill.

## Usage

All helpers live in `scripts/` and accept input on stdin, prompt/options as args, and write to stdout. Default model is `tinyllama` (override with `OLLAMA_MODEL=...`).

### Generic call

```bash
echo "your prompt here" | scripts/ollama-call.sh
# or with a system prompt:
echo "input text" | scripts/ollama-call.sh --system "You are a terse log summarizer." --prompt "Summarize in 3 bullets."
```

### Summarize a file or stream

```bash
scripts/summarize.sh /var/log/syslog --lines 5
cat huge.txt | scripts/summarize.sh --lines 3
```

### Extract structured data

```bash
cat access.log | scripts/extract.sh "all unique IP addresses, one per line"
```

### Classify

```bash
echo "fix: handle null in user parser" | scripts/classify.sh "feat,fix,chore,docs,refactor"
```

## Workflow pattern

The canonical pattern is **filter-then-think**: use Ollama to shrink the input, then read the shrunken output yourself.

```
big input ──► [ollama: summarize/extract/filter] ──► small output ──► you read it
```

Example: user asks "what errored in this 50k-line log?". Don't read the whole log. Run `summarize.sh` or `extract.sh "lines containing ERROR or stack traces"`, then read **that** output and answer.

## Cost reality check

The local model is small (tinyllama by default — ~1B params). It is bad at:
- Long-context understanding (drops things past ~2k tokens).
- Anything requiring multi-step reasoning.
- Producing structured output reliably without retries.

If a task fails twice from Ollama, stop and do it yourself. The point is to save tokens on the easy 80%, not to fight a tiny model on hard tasks.
