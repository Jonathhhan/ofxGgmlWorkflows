# Codex Qwen3.6 RTX 3090 Profile

This profile is a local Codex operating baseline for `Qwen3.6-27B-Q4_0` on an
RTX 3090 24 GB workstation. It is intentionally a guidance document, not a
checked-in model, runtime, cache, or memory index.

## Goal

Run Codex as a self-planning, self-optimizing assistant with durable project
memory while keeping the ofxGgml addon split clean.

The agent should:

- plan before multi-step work;
- measure before tuning;
- keep reusable knowledge in source-controlled docs;
- keep local memories, traces, embeddings, and caches outside git;
- prefer narrow validated changes over broad autonomous rewrites.

## Runtime Baseline

Use a conservative GPU-first profile before widening context or parallelism:

| Setting | Baseline | Notes |
| --- | ---: | --- |
| GPU layers | all available | Use full CUDA offload when the runner supports it. |
| Context | 65536 tokens | Minimum working target for the self-planning profile on a 24 GB RTX 3090. |
| Batch | 1024 tokens | Raise only after latency and VRAM headroom are measured. |
| Micro-batch | 256 tokens | Lower first if decode or prompt processing becomes unstable. |
| Parallel slots | 1 | Prefer one high-quality Codex loop over competing sessions. |
| Flash attention | enabled when supported | Disable only if the backend reports kernel instability. |
| KV cache | q4_0 for K and V | Separate from the already-Q4 model weights; keeps the 64k window as realistic as possible on 24 GB VRAM. |
| Memory lock | enabled when available | Helps avoid paging pauses on long planning turns. |
| Temperature | 0.2-0.35 | Keep coding behavior deterministic but not brittle. |
| Top-p | 0.85-0.95 | Use the lower end for edits, higher end for planning. |
| Repeat penalty | 1.05-1.10 | Enough to avoid loops without damaging code precision. |

Example llama.cpp-style launch profile:

```powershell
llama-server `
  --model C:\models\Qwen3.6-27B-Q4_0.gguf `
  --ctx-size 65536 `
  --n-gpu-layers -1 `
  --batch-size 1024 `
  --ubatch-size 256 `
  --parallel 1 `
  -ctk q4_0 `
  -ctv q4_0 `
  --flash-attn `
  --mlock
```

If VRAM pressure appears, reduce in this order: `--ctx-size`, then
`--ubatch-size`, then `--batch-size`. Avoid lowering GPU offload unless the
backend cannot keep the model resident.

## Codex Operating Loop

Use this loop for every non-trivial task:

1. Read local instructions, README, docs, scripts, and nearby files.
2. Classify the task as documentation, automation, validation, planning, or
   addon-code work.
3. Create a short plan for multi-step or cross-repo work.
4. Make the smallest useful change.
5. Run the closest validation, usually `scripts\validate-local.ps1` in this
   repository.
6. Record reusable lessons in tracked docs, not in generated memory stores.
7. Leave local traces, embeddings, scratch summaries, and caches untracked.

For ecosystem planning or cross-repo changes, run the Core planning handoff
before editing:

```powershell
..\ofxGgmlCore\scripts\plan-ecosystem.ps1
```

## Memory Policy

Codex may use memory in three layers:

| Layer | Storage | Git policy | Purpose |
| --- | --- | --- | --- |
| Project memory | `AGENTS.md`, `HERMES.md`, `README.md`, `docs\*.md` | tracked | Durable rules and reusable decisions. |
| Session notes | Codex conversation context | untracked | Current task state and short-lived plans. |
| Local retrieval | `.codex\memory`, `.codex\indexes`, vector stores, traces | ignored/untracked | Search and recall acceleration only. |

Do not commit local retrieval stores, model files, downloaded runtimes, prompts
captured from private sessions, or benchmark logs with machine-specific paths.
When a memory becomes generally useful, summarize it into a tracked doc.

## Self-Optimization Rules

The agent may tune its own workflow, but changes must be observable and
reversible:

- Change one setting or behavior at a time.
- Keep a before/after note for latency, validation result, failure mode, or
  quality improvement.
- Promote only stable, domain-neutral lessons into shared docs.
- Keep model-specific UX in companion addons unless it becomes reusable policy.
- Never let automatic tuning skip validation or generated-artifact hygiene.

Suggested measurement log fields for local, untracked notes:

```text
date, model, quant, gpu, ctx, batch, ubatch, prompt_tokens, eval_tokens,
tokens_per_second, peak_vram_gb, validation_command, validation_result, note
```

## Codex System Prompt Overlay

Use this as a local overlay when running Qwen for this addon:

```text
You are Codex for the ofxGgml addon ecosystem. Work as a self-planning,
self-optimizing coding agent with project memory. First read local repository
instructions and relevant docs. Classify the task, plan when work spans more
than one step, then make the smallest validated change. Store durable lessons
in tracked documentation and keep local memories, indexes, model files,
runtimes, caches, and generated artifacts out of git. Prefer ofxGgmlCore for
shared neutral primitives and keep companion-addon behavior in companion
addons. Validate before handoff with the closest local script.
```
