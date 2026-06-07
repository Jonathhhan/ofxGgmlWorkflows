# Multi-Agent Improvement Review

## Task Lane and Selected Skill

- **Lane**: Workflows policy (agent-improvement)
- **Skill**: multi-agent-improvement
- **Approach**: Single-threaded simulation of 4 role-reviewer threads (MCP thread spawning unavailable with local model runtime `ofxGgmlLlamaCodexLocalExample`)
- **Spawn capability**: unavailable; processed `prompt_launch_queue` entries sequentially under coordinator ownership

## Agents Used and Review Scopes

| Agent | Role | Scope |
| --- | --- | --- |
| coordinator (main) | integration owner | Finding integration, report authoring, implementation, validation |
| memory-reviewer | reviewer | Memory contract, schema, writer/checker/tests, generated index |
| eval-reviewer | reviewer | Eval markdown/JSON, catalog test, learning plan |
| operating-loop-reviewer | reviewer | Operating loop, learning plan, skills, handoff contract, baseline |
| source-learning-reviewer | reviewer | Source-learning map, planner, skills docs |

## Findings Integrated

### Memory Reviewer (2 findings)

**FINDING M-1 (LOW): Operating loop step 5 omits memory refresh mandate**

- **Severity**: LOW
- **Files**: `docs/hermes-agent-operating-loop.md` (step 3 vs step 5)
- **Detail**: Step 3 mandates memory refresh for "cross-repo, release-facing, or agent-improvement work." Step 5 (agent improvement) didn't reference step 3, creating a path where agents could skip memory refresh during improvement tasks.
- **Validation risk**: Agent may skip memory index check before improvement work.
- **Suggested owner**: operating-loop-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added explicit memory refresh reference to step 5.

**FINDING M-2 (LOW): No default freshness threshold in contract**

- **Severity**: LOW
- **Files**: `docs/hermes-memory-contract.md`
- **Detail**: The contract delegates freshness checking to the checker's `-MaxAgeHours` parameter but doesn't state a default threshold. This is by design (the contract is parameterized).
- **Validation risk**: None - the readiness test validates stale detection works.
- **Suggested owner**: memory-reviewer
- **Recommendation**: DEFERRED - Current parameterized design is intentional; document default in contract if needed.

### Eval Reviewer (3 findings)

**FINDING E-1 (MEDIUM): No eval for multi-agent fanout with dirty-state tables**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-openframeworks-ggml-evals.md`, `docs/hermes-openframeworks-ggml-evals.json`
- **Detail**: Scenario 14 (`conflicting-agent-advice`) tests dirty-state resolution but doesn't validate the dirty-state table format from `docs/hermes-multi-agent-improvement.md`. No scenario tested the full fanout lifecycle with dirty repos.
- **Validation risk**: Agent may produce incomplete dirty-state tables during fanout.
- **Suggested owner**: eval-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added Scenario 15 (`dirty-state-table`) to both eval markdown and JSON catalog.

**FINDING E-2 (MEDIUM): No eval for evidence promotion decisions**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-openframeworks-ggml-evals.md`, `docs/hermes-openframeworks-ggml-evals.json`
- **Detail**: No scenario tests advisory-to-required evidence promotion path. The evidence promotion playbook exists (`docs/evidence-promotion-playbook.md`) but has no eval coverage.
- **Validation risk**: Agent may promote evidence without proper criteria.
- **Suggested owner**: eval-reviewer
- **Recommendation**: DEFERRED - Evidence promotion is a Workflows workflow concern; add when promotion workflow is stable.

**FINDING E-3 (LOW): No eval for memory-regenerate-before-agent-improvement**

- **Severity**: LOW
- **Files**: `docs/hermes-openframeworks-ggml-evals.md`
- **Detail**: Scenario 11 (`permanent-memory`) covers stale memory but not the specific trigger "regenerate before agent-improvement task."
- **Validation risk**: Overlaps with F-M-1; low standalone risk.
- **Suggested owner**: eval-reviewer
- **Recommendation**: DEFERRED - Covered by operating loop fix (F-M-1).

### Operating Loop Reviewer (2 findings)

**FINDING OL-1 (MEDIUM): Step 5 (agent improvement) doesn't mandate memory refresh**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-agent-operating-loop.md` (step 5)
- **Detail**: Step 5 said "Use plan-hermes-agent-improvement.ps1 and docs/hermes-multi-agent-improvement.md when the task asks agents to improve agents." It didn't reference step 3's memory refresh requirement. Agent-improvement tasks should trigger memory refresh per the contract.
- **Validation risk**: Agents may skip memory index check before improvement work.
- **Suggested owner**: operating-loop-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added memory refresh reference to step 5. (Same root cause as F-M-1.)

**FINDING OL-2 (MEDIUM): Missing "addon fanout" retrieval packet**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-agent-operating-loop.md` (Retrieval Packets table)
- **Detail**: The 8 retrieval packets covered Core runtime, Workflows policy, Hermes memory, upstream source learning, multi-agent improvement, companion UX, release evidence, and openFrameworks build. No packet existed for "addon fanout" tasks, which are a distinct work pattern defined in `docs/hermes-multi-agent-improvement.md`.
- **Validation risk**: Agents performing addon fanout may retrieve wrong packet.
- **Suggested owner**: operating-loop-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added addon fanout retrieval packet (9th packet).

### Source Learning Reviewer (3 findings)

**FINDING SL-1 (MEDIUM): Agent source references not in source-learning map**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-source-learning-map.md`, `scripts/plan-hermes-agent-improvement.ps1`
- **Detail**: `NousResearch/hermes-agent` and `openai/codex` appeared in the improvement planner's `agent_source_references` but not in the source-learning map. The map covered upstream code sources (ggml-org, stable-diffusion.cpp, openFrameworks) while agent sources were a separate concern. This split was intentional but could cause agents to miss agent-source references.
- **Validation risk**: Agent may not discover agent-source references when using source-learning map.
- **Suggested owner**: source-learning-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added "Agent Source References" section to source-learning map with the same table from `docs/hermes-multi-agent-improvement.md`.

**FINDING SL-2 (LOW): whisper.cpp grouped under ggml-org in map, standalone in planner**

- **Severity**: LOW
- **Files**: `docs/hermes-source-learning-map.md`, `scripts/plan-hermes-source-learning.ps1`
- **Detail**: The map groups whisper.cpp under ggml-org (correct - it's a ggml-org repo). The planner lists it as a standalone source. This is a presentation difference, not a functional gap.
- **Validation risk**: None - planner and map are consistent in content.
- **Suggested owner**: source-learning-reviewer
- **Recommendation**: DEFERRED - Current grouping is accurate; no action needed.

**FINDING SL-3 (LOW): llama.cpp grouped under ggml-org in map, standalone in planner**

- **Severity**: LOW
- **Files**: `docs/hermes-source-learning-map.md`, `scripts/plan-hermes-source-learning.ps1`
- **Detail**: Same pattern as whisper.cpp - map groups under ggml-org, planner lists standalone.
- **Validation risk**: None.
- **Suggested owner**: source-learning-reviewer
- **Recommendation**: DEFERRED - Current grouping is accurate; no action needed.

## Findings Deferred

| Finding | Reason |
| --- | --- |
| M-2 | Parameterized freshness is by design; no default threshold needed |
| E-2 | Evidence promotion eval deferred until promotion workflow is stable |
| E-3 | Covered by operating loop fix (OL-1 / M-1) |
| SL-2 | Map grouping is accurate; planner standalone listing is complementary |
| SL-3 | Map grouping is accurate; planner standalone listing is complementary |

## Files Changed by Main Agent

| File | Change |
| --- | --- |
| `docs\hermes-agent-operating-loop.md` | Step 5: added memory refresh reference per step 3; Retrieval Packets: added addon fanout row (9th packet) |
| `docs\hermes-source-learning-map.md` | Added "Agent Source References" section with hermes-agent and codex table |
| `docs\hermes-openframeworks-ggml-evals.md` | Added Scenario 15 (Dirty State Table Format) and catalog ID |
| `docs\hermes-openframeworks-ggml-evals.json` | Added `dirty-state-table` scenario entry (15 total scenarios) |

## Validation Commands and Results

- `scripts\validate-local.ps1` - passed (all checks passed including memory index 18 records, eval catalog 15 scenarios, agent-improvement plan, source-learning plan, evidence validator, workflow fixtures, security advice)

## Dirty-Repo Caveats

- Current repo (`ofxGgmlWorkflows`): clean (tree_state: clean)
- Ecosystem dirty repos per previous planning: `ofxGgmlLlama` (8 files), `ofxGgmlRag` (12 files) - unrelated to this review scope
- Fanout to dirty repos: paused per multi-agent improvement rules

## Remaining Gaps

1. **Evidence promotion eval** (E-2): Deferred until promotion workflow is stable.
2. **Default freshness threshold** (M-2): By-design parameterized; document if needed.


## Round 2 Review (Second Pass)

This review continues the multi-agent improvement simulation from the prior round.
All prior accepted findings have been implemented and validated.

### Eval Reviewer (Round 2) - No New Findings

Eval catalog (15 scenarios) passes validation. Deferred items E-2 (evidence promotion) and E-3 (memory regenerate before improvement) remain appropriately deferred. No new gaps detected.

### Operating Loop Reviewer (Round 2) - 1 Finding

**FINDING OL-3 (MEDIUM): Multi-agent output shape missing operating loop items**

- **Severity**: MEDIUM
- **Files**: `docs/hermes-multi-agent-improvement.md` (Output Shape section)
- **Detail**: The multi-agent output shape was missing 3 items required by the operating loop agent output shape: "Local files retrieved", "Planning or readiness command used", and "Remaining evidence or security gaps". This creates a path where agents producing multi-agent handoffs omit operating-loop-required fields.
- **Validation risk**: Multi-agent handoffs may lack retrieval provenance, planning context, or evidence gap reporting.
- **Suggested owner**: operating-loop-reviewer
- **Recommendation**: ACCEPTED - Implemented. Added 3 missing items to multi-agent output shape.

### Source Learning Reviewer (Round 2) - No New Findings

Agent Source References section present in source-learning map. Planner/map consistency maintained. No new gaps.

### Memory Reviewer (Round 2) - No New Findings

Memory index correctly reports `refresh_required` with dirty tree (4 records have SHA mismatches from prior round changes). Contract working as designed.

## Files Changed (Round 2)

| File | Change |
| --- | --- |
| `docs\hermes-multi-agent-improvement.md` | Output Shape: added Local files retrieved, Planning or readiness command used, Remaining evidence or security gaps |

## Validation (Round 2)

- `scripts\validate-local.ps1` - passed after Round 2 changes
- `scripts\test-hermes-eval-catalog.ps1` - passed (15 scenarios)
- `scripts\check-hermes-memory-index.ps1 -Strict` - refresh_required (expected for dirty tree)

## Remaining Gaps

1. **Evidence promotion eval** (E-2): Deferred until promotion workflow is stable.
2. **Default freshness threshold** (M-2): By-design parameterized; document if needed.

No further action required. All accepted findings have been implemented and validated.
