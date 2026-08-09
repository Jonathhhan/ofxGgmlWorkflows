# Codex Repository Instructions

This repository is part of the ofxGgml openFrameworks addon ecosystem.

## Addon Scope

- Addon: ofxGgmlWorkflows
- Lane: reusable ecosystem automation
- Role: GitHub Actions workflow_call templates, policy checks, and ecosystem automation docs

## Ecosystem Authority

Use this repository as the primary Codex entry point for ecosystem-wide work.
`ecosystem.yaml` defines the active repository lanes, current practical priority,
required proof, and changes that require explicit user approval. `ofxGgmlCore`
remains the shared runtime base and owns the planning commands used to inspect
the ecosystem; this repository owns the governing instructions and reusable
automation used to coordinate work.

Before changing this or any companion repository:

1. Identify the observable user capability being improved.
2. Name the real execution that would prove the improvement.
3. Classify the proposed work as `runtime-capability`, `required-support`, or
   `speculative-preparation`.
4. Do not implement speculative preparation without explicit user approval.

Documentation, planning, schemas, validators, mocks, workflow infrastructure,
and new public abstractions do not by themselves count as capability progress.
Prefer completing one vertical, model-backed workflow over widening several
addon surfaces. Do not create a new addon, activate a paused lane, introduce a
speculative public API, or add another evidence schema without explicit user
approval.

For ecosystem improvement, addon development, cross-repository changes, new
APIs or abstractions, workflow or validator expansion, consolidation, or
removal, use the general `$recursive-codex` skill together with
`.agents/skills/ofxggml-capability-loop/SKILL.md`.

After implementation, report separately:

- real model-backed behavior demonstrated;
- deterministic or mock-only behavior;
- remaining unverified claims.

## Working Rules

- Read the existing code and docs before changing behavior.
- Keep edits scoped to this addon's lane and preserve the companion-addon split.
- Local repository instructions may add build, test, and backend details, but
  must not silently broaden the active scope or weaken `ecosystem.yaml`.
- Start with an ecosystem plan when a task asks for cross-repo improvement or planning.
- Use ofxGgmlCore as the default shared ggml/runtime base for companion addons; do not add reverse dependencies from Core to companion addons.
- Do not commit generated project files, binaries, model weights, downloaded runtimes, sample media dumps, memory indexes, or caches.
- Prefer focused tests and local validation over broad refactors.
- Use openFrameworks ofLogNotice, ofLogWarning, ofLogError, or module-scoped ofLog(...) for addon runtime/example logging; keep raw stdout/stderr only for tests and CLI tools with machine-readable output contracts.
- Preserve openFrameworks-style public names and document intentional breaking changes.
## Workflows Lane Contract

- Mirror the shared guidance in docs\agent-baseline.md.
- For cross-repo workflow rollout, evidence promotion, release planning, or companion PR fanout, use docs\agent-handoff-contract.md.
- Preserve workflow_call contracts and keep reusable workflow inputs stable unless the change is intentionally breaking.

## Validation

Validation before handoff: scripts\validate-local.ps1.

For ecosystem planning work, run scripts\plan-ecosystem.ps1 from ofxGgmlCore
before proposing addon-code changes.

## Ecosystem Notes

Model-specific UX belongs in companion addons. Shared code should move down into
ofxGgmlCore only after it is stable, domain-neutral, dependency-light, and
covered by focused tests.
