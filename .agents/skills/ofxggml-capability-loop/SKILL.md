---
name: ofxggml-capability-loop
description: Apply ofxGgml-specific scope, repository-lane, planning, and approval constraints alongside the general Recursive Codex method. Use for ecosystem improvement, addon development, cross-repository changes, new APIs or abstractions, workflow or validator expansion, consolidation, removal, or any proposal that could widen the ofxGgml ecosystem.
---

# ofxGgml Capability Loop

Use the general `$recursive-codex` skill for target recursion, proof honesty,
and decision recursion. Add only the following ofxGgml-specific constraints.

## Read the governing state

Read the repository-root `ecosystem.yaml`, `AGENTS.md`, and the relevant local
repository instructions before proposing or editing anything. For cross-repo
work, run the Core ecosystem plan required by `AGENTS.md` and preserve dirty
repository stop conditions.

## Keep the responsible lane

- Keep shared, stable, domain-neutral runtime primitives in `ofxGgmlCore`.
- Keep model-specific runtime behavior and UX in the companion addon.
- Keep reusable workflow contracts, policy checks, and ecosystem instructions
  in `ofxGgmlWorkflows`.
- Update an existing canonical artifact before creating another planning,
  schema, validation, memory, or handoff layer.

Preserve stable `workflow_call` inputs and the companion dependency direction.
Use `docs/agent-handoff-contract.md` only when the task actually crosses
repositories or performs rollout, promotion, release planning, or PR fanout.

## Enforce ecosystem authority

Classify work using the categories in `AGENTS.md`. Do not create an addon,
activate a paused lane, change the current priority, add an evidence schema, or
introduce a speculative public API unless `ecosystem.yaml` permits it or the
user explicitly decides it.

Report the Recursive Codex evidence levels and distinguish real model-backed
behavior from deterministic or mock-only support.
