# Hermes Multi-Agent Improvement

Use this guide when Hermes, Codex, or sibling agents use subagents to improve
the agent system itself. Multi-agent work should sharpen review and coverage,
not scatter edits across the ecosystem.

## Delegation Rules

- Start locally with Core planning, lane classification, memory readiness, and
  the smallest set of files that must change.
- Search existing canonical docs, scripts, schemas, and workflow inputs before
  adding new artifacts; update the canonical source when possible.
- Delegate only bounded sidecar reviews that can run while the main agent works
  on non-overlapping implementation.
- Keep subagents read-only unless a task has a disjoint write scope and a clear
  validation command.
- Give each subagent one question, one file set, and one expected output shape.
- Do not ask multiple agents to edit the same files or solve the same question.
- The main agent owns integration, final validation, commit scope, and dirty-repo
  caveats.

## Authority Model

- `coordinator`: the main agent that classifies the lane, spawns bounded
  sidecar reviews, and owns final integration.
- `retriever`: a read-only agent that checks local facts, memory readiness, or
  upstream source-learning packets.
- `reviewer`: a read-only agent that reports findings with severity, file
  references, and validation risks.
- `implementer`: an optional worker with a disjoint write scope and explicit
  validation command.
- `validator`: a read-only or command-running agent that checks focused tests
  while implementation continues elsewhere.
- `integrator`: exactly one owner, normally the coordinator, who accepts or
  rejects delegated outputs before validation and handoff.

## Recommended Review Roles

| Role | Read First | Output |
| --- | --- | --- |
| `memory-reviewer` | `docs\hermes-memory-contract.md`, memory schema, memory writer/checker/tests | Stale-memory, source-provenance, and handoff gaps |
| `eval-reviewer` | Hermes eval markdown/JSON, eval catalog test, learning plan | Missing scenarios, unsafe failures, and measurable readiness gaps |
| `operating-loop-reviewer` | operating loop, learning plan, skills guide, handoff contract, baseline | Delegation, anti-duplication, integration, and validation gaps |
| `source-learning-reviewer` | source-learning map/planner, openFrameworks and ggml skills | Upstream-learning, generated artifact, and lane-translation gaps |

## Addon Fanout

Use one agent per addon only when the task is a review, inventory, or advisory
rollout plan. Each addon agent should read its own `AGENTS.md`, `README.md`,
workflow docs, validation script, and generated artifact policy, then report a
lane-local finding set. The coordinator owns cross-addon comparison and final
integration.

For edit work, one agent per addon is allowed only when:

- Core planning marks that addon clean or the handoff explicitly accepts the
  dirty state.
- Each agent has a disjoint repository and write scope.
- Each agent runs or reports the addon validation command.
- The coordinator pauses fanout for dirty, owner-unknown, or generated-artifact
  changes.

## Integration Rules

Before editing, the main agent should decide which local task stays on the
critical path and which sidecar reviews can run in parallel. After reviews
return, integrate only findings that are in the Workflows lane or explicitly
fit the current handoff. Record rejected findings in the final summary when
they are useful but out of scope.

Every multi-agent handoff should name:

- Delegation roles.
- Integration owner.
- Accepted outputs.
- Rejected or unused outputs.
- Final validation owner.

Use this dirty-state table when Core planning reports dirty managed
repositories:

| Repository | Files Or Count | Relevance | Owner | Generated Artifact | Action |
| --- | --- | --- | --- | --- | --- |
| target repo | exact files or count | relevant/unrelated | user/agent/unknown | yes/no | stop/proceed |
| unrelated managed repo | exact files or count | unrelated | user/unknown | yes/no | pause fanout |

Stop instead of widening when:

- A subagent finding requires touching dirty managed repositories.
- Two subagents disagree about Core versus companion ownership.
- A finding would require generated projects, model weights, binaries, caches,
  memory indexes, or sample media.
- Validation cannot cover the new instruction, eval, or workflow behavior.
- A subagent output duplicates an existing canonical doc, script, schema, or
  workflow contract without explaining why a new artifact is needed.

## Output Shape

Multi-agent improvement handoffs should include:

- Main task lane and selected skill.
- Agents used and their review scopes.
- Findings integrated and findings deferred.
- Files changed by the main agent.
- Validation commands and results.
- Dirty-repo caveats.
- One focused next action.
