---
name: recursive-codex
description: Keep substantial project changes tied to the original user goal, an observable capability or effect, the smallest concrete path through the real material or system, claim-matched evidence, and only decision history that would otherwise be lost. Use for implementation, architecture, planning, documentation, manuscript or research revision, artistic work, new abstractions, validators, workflows, consolidation, removal, cross-component integration, or work that risks confusing declarations, checks, previews, simulations, compilation, readiness, fallbacks, or structural representation with the requested outcome.
---

# Recursive Codex

Apply two separate recursive checks: target recursion before and during the change, then decision
recursion after the result is known. Do not substitute one for the other.

## Recur on the target

Identify:

1. the original user goal;
2. the observable capability or effect that should improve;
3. the concrete performance, inspection, or use that would demonstrate it;
4. the first demonstrated blocker on that execution path;
5. the smallest change that removes that blocker.

Trace every intervention through this chain:

```text
user goal
  -> observable capability or effect
  -> concrete performance, inspection, or use
  -> first demonstrated blocker
  -> smallest necessary change
  -> verification of actual effect
```

Repeat the trace whenever work widens or adds another layer. Prefer one thin path through the real
material and responsible components over broad horizontal readiness work. Add planning, abstractions, schemas,
validators, reports, or workflow infrastructure only when they remove a demonstrated blocker or
are necessary to verify the requested outcome.

Preserve the first meaningful failure. A later wrapper error, fallback success, or aggregate
readiness score must not replace the failure that identifies the responsible layer.

## Classify evidence by kind and claim

State what occurred and which claim it supports. Use only the relevant evidence kinds:

1. **Declared:** planned, configured, documented, or structurally represented.
2. **Inspected:** statically, formally, critically, or deterministically examined; this includes schema and mock checks.
3. **Produced:** the actual candidate was compiled, rendered, revised, packaged, or otherwise made.
4. **Rehearsed:** a dry-run, simulation, preview, or launch plan was observed without the intended use.
5. **Available:** the intended artifact, process, or backend was present and ready in its target context.
6. **Exercised:** the intended operation, reading, performance, or analysis occurred with representative material or input.

These are evidence kinds, not a universal hierarchy of truth. Not every domain uses every kind, and
the active domain determines validity criteria. Never infer a use claim from production or
availability alone: compilation does not prove launch, a revised passage does not prove coherence
in context, and a fallback does not prove the primary path.

For work across components, repositories, sources, or artifacts, name the producer, recipient,
environment, configuration, revision, and exact handoff being examined. Evidence belongs to the
conditions that produced it; do not forward a report as proof for materially different conditions.

## Treat fallbacks as separate behavior

Use a fallback only when the user-facing goal permits degraded behavior. Make the transition
observable and retain the primary failure. Verify the primary path and fallback independently.
Do not count fallback success as closure when the requested capability depends on the primary path.

## Recur on the decision

After implementation and verification, ask:

> Which decision-relevant reason would disappear from project history without an additional note?

Create or update a decision note only when a consequential rationale is not already preserved by
code, tests, commit context, canonical documentation, or an existing decision record. Preserve only
the governing constraint, materially rejected alternative, consequence for later work, and evidence
that justified the decision. Do not restate the diff or validation output.

## Run autonomous reproduction

When `authority.final_decision` is `recursive-codex-system`, perform exactly one admissible
operation per invocation. Derive it from the active goal, failed checks, contradictions, deferred
possibilities, or observed consequences. Preserve the project contract, protected paths,
provenance, validation gates, recovery, and resource limits. Return quiescence when no admissible
operation exists, and stop on invariant violation rather than weakening the invariant.

The parent process owns write-requiring checks, evidence, and stabilization. A child proposal must
not claim an evidence kind or effect that the parent's observation does not support.

## Escalate only when required

If the repository has an active `.recursive-codex/project.yaml`, or the work requires explicit
authority, provenance, protected paths, autonomous stabilization, collectives, or durable structured
events, read and follow [full-protocol.md](references/full-protocol.md). Existing project contracts
remain authoritative; this default workflow does not weaken them.

## Close against the user goal

State:

- which requested capability or effect now holds;
- the concrete performance, inspection, or use that demonstrated it;
- other evidence kinds that must not be mistaken for that outcome;
- remaining unverified claims and the next observation needed;
- whether a decision record was necessary and why.
