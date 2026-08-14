# Codex Ecosystem Usage Guide

## Start from ecosystem authority

`ofxGgmlWorkflows` is the authority entry point for ecosystem-wide Codex work.
Its generated `AGENTS.md` is the binding bootstrap instruction. Before proposing
changes, Codex must:

1. read `ecosystem.yaml` for active, experimental, paused, priority, exclusion,
   and approval state;
2. load the repository-local `$recursive-codex` and
   `$ofxggml-capability-loop` skills from `.agents/skills`;
3. run `scripts\plan-ecosystem.ps1` from `ofxGgmlCore` for cross-repository
   work; and
4. stop at dirty-repository or missing-authority conditions rather than widening
   the task.

The repository-local Recursive Codex skill is intentionally vendored. A fresh
checkout must not depend on a skill installed elsewhere on the machine.

## Follow the capability loop

Every ecosystem intervention begins with this chain:

```text
user goal
  -> observable capability or effect
  -> concrete execution that would demonstrate it
  -> first demonstrated blocker
  -> smallest necessary change
  -> claim-matched evidence
```

Classify the proposed change as one of:

- **runtime capability:** directly changes observable addon behavior;
- **required support:** removes a demonstrated blocker or verifies the requested
  behavior; or
- **speculative preparation:** infrastructure for a possible future need, which
  requires explicit approval.

Planning, documentation, schemas, validators, mocks, workflow infrastructure,
and new public abstractions do not count as capability progress by themselves.
They are justified only when they remove the first demonstrated blocker or are
needed to verify the requested effect.

## Keep repository lanes and dependencies explicit

- `ofxGgmlCore` owns stable, dependency-light, domain-neutral ggml/runtime
  primitives and ecosystem planning tools.
- Companion addons own model-specific runtime behavior, UX, and examples.
- `ofxGgmlWorkflows` owns reusable `workflow_call` contracts, policy checks,
  ecosystem instructions, and cross-repository automation.

Core must never depend on companion addons. Core is the default shared runtime
base for companions whose implementation actually uses its primitives, but the
dependency is not universal or implicit. Each addon declares its real build
dependency in its own metadata and `addons.make` files.

`ofxGgmlAgents` is intentionally runtime-link independent from
`ofxGgmlCore`: it coordinates capabilities through explicit adapters and
contracts. Do not add Core merely to make the dependency graph look uniform.

## Improve the entire ecosystem

For a request such as "Improve the entire ofxGgml ecosystem", the expected
bootstrap is:

1. Read this repository's `AGENTS.md`, `ecosystem.yaml`, and both local skills.
2. Run the Core ecosystem plan and report dirty, missing, paused, or excluded
   repositories.
3. Restate the user goal as one observable capability and name the concrete
   execution that would prove improvement.
4. Attempt or inspect that narrow vertical path in the responsible addon.
5. Preserve the first meaningful failure as the blocker.
6. Change only the smallest responsible component, then repeat the concrete
   execution.
7. Report evidence as declared, inspected, produced, rehearsed, available, or
   exercised without promoting one kind into another.

Do not begin by inventing a workflow, validator, schema, addon, public API, or
new planning layer. Do not activate paused lanes, change the current priority,
or add evidence schemas unless `ecosystem.yaml` or an explicit user decision
provides that authority.

## Use workflows only for a demonstrated automation blocker

Create or change a reusable workflow only when repeated repository automation
is the demonstrated blocker. Preserve existing `workflow_call` inputs unless a
breaking change is intentional and authorized. Keep caller workflows small and
place shared policy in this repository.

For rollout, evidence promotion, release planning, or companion PR fanout, use
`docs\agent-handoff-contract.md`. A handoff names the producer and recipient,
revisions, exact transfer, validation, dirty-repository caveats, and stop
conditions; it is coordination evidence, not proof of runtime behavior.

## Evidence and validation

Use the evidence terms from `$recursive-codex` precisely:

- **Declared:** configured, documented, or represented.
- **Inspected:** statically or deterministically checked.
- **Produced:** built, rendered, revised, or packaged.
- **Rehearsed:** dry-run, preview, or launch plan observed.
- **Available:** present and ready in the target context.
- **Exercised:** the intended operation ran with representative input.

The `proof` values in `ecosystem.yaml` are stable claim identifiers, not proof
artifacts. A capability may use `status: proven` only when current evidence is
linked to the relevant commit, backend, observation time, and reproducibility
context. Local smoke output without a commit association, a historical workflow
result, or an unlinked claim name remains `verification_required`.

Run `scripts\validate-local.ps1` for Workflows changes. Run the owning addon's
focused validation for runtime changes. Compilation is produced evidence, not
proof that an example launched or inference completed. A fallback is separate
behavior and cannot prove the requested primary path.

## Close the task

Report the capability that now holds, the concrete execution that demonstrated
it, evidence that must not be overstated, and the next observation needed for
any remaining claim. Preserve a separate decision record only when an important
rationale would otherwise disappear from code, tests, canonical documentation,
or commit history.
