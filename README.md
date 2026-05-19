# Ollama-Skill

A Claude Code skill that teaches Claude to offload narrow, mechanical subtasks to a **local Ollama instance** instead of burning Anthropic tokens on them.

The fundamental insight: Claude (the hosted model) can't reach `localhost:11434`. But **Claude Code** (running on your machine) can. So Claude Code can run cheap labor — bulk summarization, regex-style extraction, simple classification — through a small local model before doing the actual thinking work itself.

## What's in here

```
.
├── SKILL.md            # Instructions Claude Code reads — when/how to use Ollama
└── scripts/
    ├── ollama-call.sh  # Generic POST /api/generate wrapper
    ├── summarize.sh    # N-bullet summary of a file or stdin
    ├── extract.sh      # Pull structured items out of text
    └── classify.sh     # Bucket input into one of N labels
```

## Requirements

- [Ollama](https://ollama.com) running on `localhost:11434`
- At least one model pulled (`ollama pull tinyllama` for the default, or any other)
- `bash`, `curl`, and `python3` on PATH (python3 is used for safe JSON encoding — no `jq` needed)

## Install

Drop the skill into your Claude Code skills directory:

```bash
git clone https://github.com/evanallen13/Ollama-Skill ~/.claude/skills/ollama
```

Claude Code auto-discovers skills under `~/.claude/skills/` and loads `SKILL.md` when its description matches the task.

## Use the scripts standalone

The helpers work fine outside Claude Code too:

```bash
# Summarize a log into 3 bullets
./scripts/summarize.sh /var/log/syslog --lines 3

# Pull every IP from access.log
cat access.log | ./scripts/extract.sh "all unique IPv4 addresses, one per line"

# Classify a commit message
echo "fix: null deref in parser" | ./scripts/classify.sh "feat,fix,chore,docs,refactor"

# Generic call with custom system prompt
echo "long text..." | ./scripts/ollama-call.sh \
  --system "You output only JSON." \
  --prompt "Extract name, age as a JSON object."
```

## Configuration

| Env var        | Default                  | Notes                          |
|----------------|--------------------------|--------------------------------|
| `OLLAMA_MODEL` | `tinyllama`              | Any model you've `ollama pull`ed |
| `OLLAMA_HOST`  | `http://localhost:11434` | Point at a remote Ollama too   |
| `PYTHON`       | `python3`                | Override the Python binary     |

Tinyllama is the default because it's the smallest useful model. **It is dumb.** For better results pull something heavier (`llama3.1:8b`, `qwen2.5:7b`) and set `OLLAMA_MODEL` accordingly. The skill is designed to fall back to Claude itself when the local model fails, so even a weak model is useful for the easy 80%.

## Design notes

The skill's `SKILL.md` is deliberately conservative about *when* to delegate. It explicitly tells Claude **not** to use Ollama for code writing, reasoning, or anything where a wrong answer matters. The pattern is **filter-then-think**: shrink the input with the local model, then let Claude read the small output.

This is why it saves tokens. If a 50k-line log gets piped straight into Claude's context, that's 50k lines of input cost. If Ollama first reduces it to 10 relevant lines, Claude only pays for those 10 lines plus its actual answer.

## License

MIT — do what you want.
