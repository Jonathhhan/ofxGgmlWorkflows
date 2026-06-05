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

Each role profile should have exactly one review question, a clear lane
boundary, an explicit authority, and a small output contract. Reviewers may
read bounded local files and report findings with severity, file references,
validation risk, and suggested owner. They may not edit files, commit generated
artifacts, or act as the final integrator unless the coordinator assigns a
separate disjoint write scope.

| Role | Specialization | Skill | Read First | Output Contract |
| --- | --- | --- | --- | --- |
| `memory-reviewer` | Permanent memory integrity, provenance, and freshness | `memory-contract-auditor` | `docs\hermes-memory-contract.md`, memory schema, memory writer/checker/tests | Stale-memory, source-provenance, readiness, and validation gaps |
| `eval-reviewer` | Prompt-only eval coverage and anti-gaming review | `evaluation-gap-finder` | Hermes eval markdown/JSON, eval catalog test, learning plan | Missing scenarios, unsafe failures, scoring gaps, and readiness thresholds |
| `operating-loop-reviewer` | Delegation flow, integration ownership, and handoff discipline | `operating-loop-contract-reviewer` | operating loop, learning plan, skills guide, handoff contract, baseline | Delegation, anti-duplication, integration, dirty-repo, and validation gaps |
| `source-learning-reviewer` | Upstream source translation without lane leakage | `source-learning-boundary-reviewer` | source-learning map/planner, openFrameworks and ggml skills | Upstream-learning, Core/companion ownership, generated artifact, and retrieval packet gaps |

Use `scripts\plan-hermes-agent-improvement.ps1 -Json` as the canonical
machine-readable profile source. It emits each role's `specialization`, `skill`,
`authority`, `lane_boundary`, `allowed_actions`, `forbidden_actions`,
`output_contract`, `evidence`, `prompt_packet`, and `stop_conditions`.

Each `prompt_packet` is the launch contract for a sidecar agent. It should name
the role, restate the specialization, repeat the one review question, and
require severity, file references, validation risk, suggested owner, and an
accepted or deferred recommendation in the response.

The planner also emits `prompt_launch_queue`, which flattens selected role and
addon prompt packets into launchable work items. Use
`scripts\plan-hermes-agent-improvement.ps1 -Focus addon-fanout -PromptQueue -Json`
when spawning sidecar agents because the queue carries the packet type, id,
specialization, launch mode, validation owner, and prompt text without requiring
callers to inspect the full plan shape.

## Addon Fanout

Use one agent per addon only when the task is a review, inventory, or advisory
rollout plan. Each addon agent should read its own `AGENTS.md`, `README.md`,
workflow docs, validation script, and generated artifact policy, then report a
lane-local finding set. The coordinator owns cross-addon comparison and final
integration.

Each addon brief should include:

- Repository, lane, and specialized `agent_id`.
- Lane-specific specialization and one primary review question.
- `read_first` files, validation command, dirty policy, generated artifact
  policy, and coordinator handoff owner.
- A `prompt_packet` that can be passed directly to the addon reviewer.
- Output shape: findings with severity and file references, lane-local risks,
  validation notes, and deferred or out-of-lane items.

Recommended addon specializations:

| Addon | Agent Id | Specialization |
| --- | --- | --- |
| `ofxGgmlCore` | `core-runtime-boundary-agent` | Shared ggml provider, runtime ownership, and ecosystem control-plane review |
| `ofxGgmlLlama` | `llama-text-agent` | Text, chat, embedding, and llama.cpp caller workflow review |
| `ofxGgmlSam` | `sam-segmentation-agent` | Segmentation examples, SAM/SAM2 setup, and visual evidence review |
| `ofxGgmlAudio` | `audio-speech-agent` | Audio capture, transcription, and speech evidence review |
| `ofxGgmlMusic` | `music-generation-agent` | MusicGen, AceStep, prompt UX, and audio artifact hygiene review |
| `ofxGgmlVision` | `vision-understanding-agent` | Image understanding, detector/classifier evidence, and metadata review |
| `ofxGgmlVideo` | `video-pipeline-agent` | Video montage, frame pipeline, and temporal evidence review |
| `ofxGgmlStableDiffusion` | `diffusion-image-agent` | stable-diffusion.cpp setup, image generation UX, and model artifact hygiene review |
| `ofxGgmlRag` | `rag-memory-agent` | RAG retrieval, citation provenance, and memory boundary review |
| `ofxGgmlAgents` | `local-agent-tools-agent` | Local tool-agent workflows, permissions, and delegation contract review |
| `ofxGgmlWorkflows` | `workflows-coordinator-agent` | Workflow policy, reusable CI contracts, and integration owner |

## Agent Source References

Use external agent repositories as source-learning references only. Do not
vendor their code, copy their runtime architecture wholesale, or let their
claims override local evidence and ofxGgml lane boundaries.

| Source | Learn From | Translate To |
| --- | --- | --- |
| `NousResearch/hermes-agent` | learning-loop design, skill creation, persistent searchable memory, isolated subagent fanout | source-grounded memory records, specialized prompt packets, bounded sidecar reviewers, agent-improvement evals |
| `openai/codex` | local coding-agent ergonomics, repository instruction discovery, terminal-first validation workflow, handoff discipline | `AGENTS.md`/`HERMES.md` layering, local validation before handoff, explicit permissions, clean final summaries |

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
