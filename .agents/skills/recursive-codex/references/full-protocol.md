# Full protocol escalation

Use this protocol only when an active project contract or the work's authority, provenance,
security, or stabilization requirements demand it.

## Load the contract

1. Read `.recursive-codex/project.yaml` and the referenced domain profile completely.
2. Resolve authority, protected paths, required sources, vocabulary constraints, and checks.
3. Distinguish current state, source material, proposal, reviewer finding, and accepted decision.
4. Stop if required authority is absent.

If no contract exists, initialize one only when the full protocol is actually required and the user
authorizes the added project structure.

## Classify and execute

Classify the primary operation as `local_update`, `composition`, `revision`, `reorganization`, or
`audit`. Use the wider class when effects cross components.

Run the recursive cycle:

```text
connect -> organize -> update -> review relations -> critique -> stabilize
```

Return to the target recursion whenever review changes the problem. The full cycle does not replace
direct observation of the requested outcome.

## Variants, collectives, and events

Execute multiple variants only when materially different solutions remain plausible. Use
independent reviewer roles only for contested structural work or when requested; reviewers advise
and the declared authority decides. Read [collectives.md](collectives.md) when using them.

For every `revision`, `reorganization`, or substantial `composition`, create an event before
editing. Start from the active project's `templates/change-event.yaml` when it exists; otherwise
start from the skill's `assets/change-event.yaml` or an embedded
`<recursive_codex_event_template>` block. Stop if none of these resources can be resolved. Record
baseline, scope, provenance, actual relations and consequences, meaningful variants, authority,
evidence, and recovery. Read [change-events.md](change-events.md) for field semantics.

## Autonomous stabilization

When `authority.final_decision` is `recursive-codex-system`, continue only within the contract's
allowed scope, invariants, protected paths, validation gates, recovery requirements, and resource
limits. Never reinterpret a failed invariant as permission to remove it. Stop at quiescence,
resource exhaustion, or invariant violation.

## Close

Run every declared check plus the project and event validators. Report them as structural-check
evidence unless they also perform the concrete use, reading, analysis, or operation at issue.
Stabilize only with the declared authority and keep each claim bound to the evidence that supports it.
