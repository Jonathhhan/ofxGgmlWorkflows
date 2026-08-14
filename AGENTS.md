# Codex Repository Instructions

This repository is part of the ofxGgml openFrameworks addon ecosystem.

## Addon Scope

- Addon: ofxGgmlWorkflows
- Lane: reusable ecosystem automation
- Role: GitHub Actions workflow_call templates, policy checks, and ecosystem automation docs

## Working Rules

- Read the existing code and docs before changing behavior.
- Keep edits scoped to this addon's lane and preserve the companion-addon split.
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
## Ecosystem Authority

For requests to improve, review, plan, or coordinate the ofxGgml ecosystem:

1. Read `ecosystem.yaml` before proposing changes. Treat its active,
   experimental, paused, priority, exclusion, and approval fields as binding.
2. Load the repository-local `$recursive-codex` and
   `$ofxggml-capability-loop` skills from `.agents/skills`; do not rely on a
   globally installed skill.
3. Name the chain from the user goal to an observable capability, a concrete
   execution that would demonstrate it, the first demonstrated blocker, the
   smallest necessary change, and claim-matched evidence.
4. Classify proposed work as runtime capability, required support, or
   speculative preparation. Speculative preparation requires explicit user
   approval.
5. Treat `proof` values in `ecosystem.yaml` as claim identifiers, not evidence.
   A `proven` status requires current evidence linked to the relevant commit,
   backend, observation time, and reproducibility context. Otherwise use
   `verification_required` and name the missing observation.
6. Do not count documentation, planning, schemas, validators, mocks, workflow
   infrastructure, or new public abstractions as capability progress by
   themselves.
7. Do not create addons, activate paused lanes, change the current priority,
   add evidence schemas, or introduce speculative public APIs without the
   authority required by `ecosystem.yaml` or an explicit user decision.

Prefer the smallest vertical path through the responsible addon. Preserve the
first meaningful failure and distinguish declared, inspected, produced,
rehearsed, available, and exercised evidence.

## Validation

Validation before handoff: scripts\validate-local.ps1.

For ecosystem planning work, run scripts\plan-ecosystem.ps1 from ofxGgmlCore
before proposing addon-code changes.

## Ecosystem Notes

Model-specific UX belongs in companion addons. Shared code should move down into
ofxGgmlCore only after it is stable, domain-neutral, dependency-light, and
covered by focused tests.
