# Hermes Ecosystem Learning Plan

This plan turns the ofxGgml operating model into a stable learning path for
Hermes and sibling coding agents. It is not a fine-tuning plan. Prefer this
instruction, retrieval, skill, and evaluation stack before changing model
weights or widening runtime behavior.

## Instruction Layer

Give Hermes a compact system and workflow brief before each ecosystem task:

- openFrameworks project layout: addon root, `addon_config.mk`, `src`,
  root-level examples, `addons.make`, docs, scripts, tests, and ignored
  generated project files.
- Addon boundaries: each companion addon owns one model or workflow lane;
  `ofxGgmlWorkflows` owns reusable `workflow_call` policy; `ofxGgmlCore` owns
  shared runtime, planning, and ecosystem control-plane behavior.
- Logging conventions: use `ofLogNotice`, `ofLogWarning`, `ofLogError`, or
  module-scoped `ofLog(...)` for addon runtime and examples. Keep raw
  stdout/stderr for tests and machine-readable CLI contracts.
- Build and validation rules: run Core planning before cross-repo work, use the
  smoke-build target lifecycle before projectGenerator, avoid generated project
  files, and run the touched repository's `scripts\validate-local.ps1`.
- ggml/Core provider rules: use `ofxGgmlCore` as the default ggml runtime
  provider, avoid reverse dependencies from Core to companions, and keep
  optional backend evidence honest.
- Ownership rule: Core owns shared runtime; companion addons own model UX,
  model setup scripts, prompts, examples, generated evidence, and domain
  workflow behavior.

## RAG And Memory Layer

Index ecosystem facts so Hermes can retrieve them instead of memorizing them.
Start with managed repositories and ignore classified legacy/reference clones
unless a human explicitly promotes one.

Priority documents:

- `ofxGgmlCore\AGENTS.md`
- `ofxGgmlCore\docs\ECOSYSTEM_AGENT.md`
- `ofxGgmlCore\docs\COMPANIONS.md`
- `ofxGgmlCore\docs\RUNTIME_PROVIDER.md`
- `ofxGgmlCore\docs\backend-runtime-verification-strategy.md`
- each managed addon's `AGENTS.md`, `README.md`, and `docs\*WORKFLOWS.md`
- `ofxGgmlWorkflows\docs\agent-baseline.md`
- `ofxGgmlWorkflows\docs\hermes-openframeworks-ggml-skills.md`
- `ofxGgmlWorkflows\docs\hermes-source-learning-map.md`
- `ofxGgmlWorkflows\docs\hermes-agent-operating-loop.md`
- `ofxGgmlWorkflows\docs\evidence-schema-v1.md`
- selected openFrameworks docs and examples that explain addon layout,
  `addons.make`, projectGenerator, Visual Studio builds, and example structure
- selected ggml headers and docs plus Core runtime/provider docs
- official source references for `ggml-org`, `stable-diffusion.cpp`, and
  `openFrameworks` when learning upstream implementation and layout patterns

Priority scripts:

- `ofxGgmlCore\scripts\plan-ecosystem.ps1`
- `ofxGgmlCore\scripts\check-ecosystem-readiness.ps1`
- `ofxGgmlCore\scripts\plan-release-readiness.ps1`
- `ofxGgmlCore\scripts\plan-backend-runtime-verification.ps1`
- `ofxGgmlCore\scripts\setup-ggml.ps1`
- each managed addon's `scripts\validate-local.ps1`
- companion-owned setup, smoke, and evidence scripts referenced by the local
  workflow docs

Memory records should store source path, commit SHA when available, repository
lane, freshness timestamp, and whether the source is instruction, workflow,
runtime, evidence, validation, planning, release, security, memory, or example
material. Use `docs\hermes-memory-contract.md` and
`scripts\write-hermes-memory-index.ps1` for the Workflows lane memory index,
then use `scripts\check-hermes-memory-index.ps1` before relying on it. The
generated index is a build artifact, not committed source, and stale records
must yield to current repository files.

Use `scripts\plan-hermes-source-learning.ps1 -Json` when Hermes needs a
machine-readable retrieval packet for upstream source learning.
Use `scripts\plan-hermes-agent-improvement.ps1 -Json` when Hermes needs
subagents or sibling agents to review agent instructions, memory, evals, or
operating-loop behavior. Treat its specialized role profiles and addon lane briefs
as the canonical delegation packet before spawning reviewers, and use each
`prompt_packet` when launching a sidecar review.
Use its `agent_source_references` to learn from `NousResearch/hermes-agent` and
`openai/codex` without vendoring their code or weakening local ofxGgml
boundaries.

## Skill Layer

Hermes should call or follow small named skills rather than one broad mental
model:

- `openframeworks-addon-layout`: inspect addon shape, examples, generated
  artifact hygiene, logging conventions, and validation entrypoints.
- `ggml-runtime-provider`: check Core provider rules, backend declarations,
  setup scripts, optional runtime artifacts, and reverse dependency risks.
- `upstream-source-learning`: inspect upstream `ggml`, `llama.cpp`,
  `whisper.cpp`, `stable-diffusion.cpp`, and `openFrameworks` patterns, then
  translate the lesson into a Core, Workflows, or companion lane decision before
  editing. Use `scripts\plan-hermes-source-learning.ps1` to select the source
  folders for the requested lane.
- `ofxggml-ecosystem-planning`: run Core planning/readiness first, classify
  dirty repos, choose one lane, and write a handoff before cross-repo edits.
- `multi-agent-improvement`: use specialized bounded read-only reviewers by
  default, assign exactly one integration owner, avoid duplicate write scopes,
  use source-learning references for agent-loop patterns, and report accepted
  and rejected outputs before validation.
- `windows-vs-openframeworks-build`: use Visual Studio/openFrameworks build
  wrappers, projectGenerator preflight/postflight, and generated-project repair
  planners without committing generated files.
- `ace-step-ggml-ops`: keep AceStep/MusicGen setup, model-load, generation, and
  smoke evidence separated in the music lane.
- `release-readiness-evidence`: read release readiness JSON, identify evidence
  gaps, preserve Evidence Schema v1, and recommend advisory-to-required
  promotion only after repeated clean runs.

Each skill should state:

- Inputs and source documents to retrieve.
- Stop conditions.
- Allowed files or repository lanes.
- Validation command.
- Handoff output shape.

## Evaluation Layer

Before fine-tuning or broad automation, test Hermes on repeatable tasks:

- Add a validation check without touching generated projects.
- Explain why Core must not depend on Music.
- Diagnose missing ggml CUDA runtime.
- Patch a companion addon to use the Core provider.
- Plan release evidence gaps from `plan-release-readiness.ps1 -Json` output.
- Classify whether a task belongs in Core, Workflows, or a companion addon.
- Convert a companion smoke result into Evidence Schema v1 without moving
  model-specific behavior into Workflows.
- Review a projectGenerator handoff and reject unsafe generated project churn.

Evaluation should score:

- Boundary correctness.
- Retrieval-grounded citations to local files.
- Memory freshness and source-path correctness.
- Generated artifact hygiene.
- Correct logging and validation conventions.
- Evidence honesty and release-readiness judgment.
- Minimal, lane-scoped edits.

## Operating Order

1. Refresh Core planning or readiness.
2. Use `docs\hermes-agent-operating-loop.md` to classify the lane, retrieval
   packet, stop conditions, and handoff shape.
3. Retrieve the instruction layer and relevant lane docs.
4. Refresh or verify the Hermes memory index, then check readiness when the
   task is cross-repo, release-facing, or agent-improvement work.
5. Use the multi-agent improvement planner when delegating agent-improvement
   reviews.
6. Select the smallest applicable skill.
7. Execute only inside the chosen lane.
8. Validate locally.
9. Report commands, dirty-repo caveats, evidence gaps, and next action.
