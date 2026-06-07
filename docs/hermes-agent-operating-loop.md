# Hermes Agent Operating Loop

Hermes should work as a cautious ecosystem operator, not as a generic code
rewriter. Use this loop before touching managed ofxGgml repositories.

## Loop

1. Classify the task lane: Core runtime, Workflows policy, companion UX,
   documentation, validation, or release evidence.
2. Run or read Core planning when the task is cross-repo, release-facing, or
   likely to affect generated openFrameworks projects.
3. Refresh or verify `docs\hermes-memory-contract.md` and check the generated
   memory index with `scripts\check-hermes-memory-index.ps1` when the task is
   cross-repo, release-facing, or agent-improvement work.
4. Use `scripts\plan-hermes-source-learning.ps1` when the task asks Hermes to
   learn from upstream code before editing.
5. Use `scripts\plan-hermes-agent-improvement.ps1` and
   `docs\hermes-multi-agent-improvement.md` when the task asks agents to
   improve agents. Refresh the memory index per step 3 before starting
   improvement work, as agent-improvement tasks require current memory state.
6. Retrieve the smallest packet of local facts for that lane.
7. Choose one named skill from `docs\hermes-ecosystem-learning-plan.md`.
8. Search canonical docs, scripts, schemas, and workflows before adding new
   agent artifacts.
9. Edit only files owned by the chosen lane.
10. Validate locally with the touched repository's validation command.
11. Report dirty-repo caveats, files changed, validation result, evidence gaps,
    and one focused next action.

## Retrieval Packets

| Lane | Retrieve First |
| --- | --- |
| Core runtime | `ofxGgmlCore\AGENTS.md`, `docs\ECOSYSTEM_AGENT.md`, `docs\COMPANIONS.md`, `docs\RUNTIME_PROVIDER.md`, backend verification docs |
| Workflows policy | `ofxGgmlWorkflows\AGENTS.md`, `docs\agent-baseline.md`, `docs\workflow-adoption.md`, `docs\evidence-schema-v1.md`, relevant reusable workflow |
| Hermes memory | `ofxGgmlWorkflows\docs\hermes-memory-contract.md`, `schemas\hermes-memory-v1.schema.json`, `scripts\write-hermes-memory-index.ps1`, `scripts\check-hermes-memory-index.ps1`, generated memory index when present |
| Upstream source learning | `ofxGgmlWorkflows\docs\hermes-source-learning-map.md`, `scripts\plan-hermes-source-learning.ps1`, local lane docs, selected upstream source folders |
| Multi-agent improvement | `ofxGgmlWorkflows\docs\hermes-multi-agent-improvement.md`, `scripts\plan-hermes-agent-improvement.ps1 -Json`, `scripts\plan-hermes-agent-improvement.ps1 -PromptQueue -Json`, `-QueueType`, `-QueueId`, specialized role profiles, addon lane briefs, `prompt_packet` launch prompts, `prompt_launch_queue`, agent baseline, handoff contract, eval catalog |
| Companion UX | companion `AGENTS.md`, `README.md`, `addon_config.mk`, examples, lane workflow docs, validation script |
| Release evidence | Core release-readiness output, Workflows evidence docs, evidence JSON, `workflow-security-advice.yml`, artifact digest or attestation fields |
| openFrameworks build | Core smoke-build target lifecycle, companion examples, `addons.make`, generated project preflight and postflight reports |
| Addon fanout | `docs\hermes-multi-agent-improvement.md` (addon fanout section), addon `AGENTS.md`, `README.md`, validation script, generated artifact policy, dirty-state table, coordinator handoff rules |

## Stop Conditions

Stop and ask for a narrower handoff when:

- Core planning reports dirty managed repositories that are relevant to the
  task.
- Dirty-state table classifies the current repo or target repo as relevant,
  generated, or owner-unknown in a way that could affect the change.
- The requested change crosses from companion UX into Core runtime without a
  stable, domain-neutral contract.
- The task requires committing generated project files, model weights, runtime
  binaries, sample media dumps, memory indexes, or caches.
- The memory index commit, freshness, or `source_path` records are stale for
  the files that would guide the task.
- Release evidence is only a declaration, library presence check, or stale
  artifact.
- A workflow input contract would break existing callers without an explicit
  versioned release plan.

## Agent Output Shape

Hermes handoffs should include:

- Task lane and selected skill.
- Agents used, delegation roles, integration owner, accepted outputs, and
  rejected or unused outputs.
- Local files retrieved.
- Planning or readiness command used.
- Files changed.
- Validation command and result.
- Dirty-repo caveats.
- Remaining evidence or security gaps.
- One focused next action.
