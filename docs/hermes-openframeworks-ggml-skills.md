# Hermes openFrameworks and ggml Skills

This guide teaches Hermes, Codex, Copilot, and future ecosystem agents how to
work inside the ofxGgml openFrameworks addon family without crossing addon
boundaries or inventing unstable runtime policy.

## Purpose

- Learn the local openFrameworks addon shape before editing behavior.
- Learn the ggml runtime split before moving shared code or evidence policy.
- Use `docs\hermes-ecosystem-learning-plan.md` when a task asks how Hermes
  should learn, retrieve, evaluate, or practice ecosystem work.
- Use `docs\hermes-agent-operating-loop.md` when a task asks Hermes to act,
  improve agents, perform cross-repo planning, or choose an edit lane.
- Prefer documentation, validation, workflow, and planning changes when the
  requested improvement is about agents or ecosystem coordination.
- Keep model-specific UX and runtime behavior in companion addons unless the
  user explicitly asks for shared Core behavior.

## openFrameworks Skill Loop

- Read `addon_config.mk`, `README.md`, `src`, example folders, docs, scripts,
  and local tests before changing public behavior.
- Preserve openFrameworks-style public names, example naming, and addon layout.
- Use `ofLogNotice`, `ofLogWarning`, `ofLogError`, or module-scoped `ofLog(...)`
  for addon runtime and example logging; reserve raw stdout/stderr for tests
  and CLI tools with machine-readable output.
- Keep generated project files, build folders, IDE metadata, binaries, sample
  media dumps, and caches out of commits.
- Run the Core smoke-build target lifecycle before using projectGenerator:
  select a target, check preflight, generate only when ready, run postflight,
  and use the repair planner when addon wiring is incomplete.
- Keep example changes focused on the addon's lane and document intentional
  breaking changes.

## ggml Skill Loop

- Treat `ofxGgmlCore` as the shared ggml/runtime base and planning/control
  plane for companion addons.
- Do not add reverse dependencies from Core to companion addons.
- Keep model-specific runtime setup, prompts, UI, scripts, sample assets, and
  generated evidence in the companion addon that owns that model lane.
- Move code into Core only when it is stable, domain-neutral,
  dependency-light, and covered by focused tests.
- Keep backend evidence honest: include backend, runner/device context,
  workflow provenance, commit SHA, tree state, timing, producer, and artifact
  integrity when a workflow or release gate depends on runtime claims.
- Use Evidence Schema v1 and Workflows validators for advisory-to-required
  evidence promotion instead of inventing per-addon policy.
- Preserve reusable `workflow_call` contracts when a ggml evidence or runtime
  policy change touches Workflows automation.

## Review Checklist

- Operating loop: task lane, retrieval packet, skill, stop conditions, and
  handoff shape were selected before edits.
- Boundary: the change belongs to this addon lane or has an explicit cross-repo
  handoff.
- Skill fit: openFrameworks layout and ggml runtime ownership were checked
  before editing.
- Hygiene: no generated project files, binaries, model weights, downloaded
  runtimes, media dumps, memory indexes, caches, or IDE metadata were added.
- Evidence: runtime or backend claims use existing Workflows evidence contracts.
- Evidence detail: artifact integrity is captured when promotion or release
  policy depends on generated runtime evidence.
- Validation: the touched repository's local validation command passed, and
  cross-repo planning reports dirty-repo stop conditions.

## Handoff Commands

For ecosystem planning, start from Core:

```powershell
..\ofxGgmlCore\scripts\plan-ecosystem.ps1
```

For this repository, validate before handoff:

```powershell
scripts\validate-local.ps1
```

For action selection, use:

```text
docs\hermes-agent-operating-loop.md
```
