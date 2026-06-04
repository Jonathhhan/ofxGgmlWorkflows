# Agent Baseline

This baseline keeps Hermes, Codex, GitHub Copilot, and future coding agents
aligned when working in the ofxGgml ecosystem. Repository-specific instruction
files should remain self-contained, but they should mirror these principles.

## Scope

- Treat each addon as a lane with clear ownership.
- Keep `ofxGgmlWorkflows` focused on reusable `workflow_call` templates,
  policy checks, evidence validation, and ecosystem automation docs.
- Keep `ofxGgmlCore` as the shared base and planning/control plane.
- Keep companion addons responsible for model-specific UX, runtime behavior,
  caller scripts, and generated evidence.

## Planning

- Start cross-repo improvement, rollout, evidence promotion, release planning,
  or companion fanout with a fresh Core planning or readiness command.
- Use `docs\agent-handoff-contract.md` when handing cross-repo work to another
  agent, repository, or PR.
- Record dirty-repo caveats and stop conditions before widening changes.
- Prefer one companion workflow adoption PR at a time unless Core emits an
  explicit fanout queue.

## Editing

- Work in instruction, documentation, workflow, validation, or planning files
  first when the goal is better agent or ecosystem behavior.
- Do not edit addon runtime behavior unless the user explicitly asks for addon
  behavior.
- Keep reusable policy in `ofxGgmlWorkflows`; keep repository-specific build,
  runtime, and evidence generation commands in caller repositories.
- Move shared helpers into `ofxGgmlCore` only after they are stable,
  domain-neutral, dependency-light, and covered by focused tests.
- Use `docs\hermes-openframeworks-ggml-skills.md` as the shared learning loop
  for openFrameworks addon shape, ggml runtime ownership, evidence honesty, and
  generated artifact hygiene.

## Agent Skills

- For openFrameworks work, learn `addon_config.mk`, `src`, examples, docs,
  scripts, tests, logging conventions, projectGenerator lifecycle, and generated
  artifact boundaries before editing behavior.
- For ggml work, keep Core as the shared runtime base, keep model-specific UX
  and setup in companion addons, avoid reverse Core dependencies, and promote
  shared code only after it is stable, neutral, light, and tested.
- For runtime and backend claims, use Evidence Schema v1 and reusable workflow
  validators so evidence includes backend, runner/device context, provenance,
  commit SHA, tree state, timing, producer, and artifact integrity.
- For handoff, report the Core planning/readiness command, dirty-repo stop
  conditions, local validation, and any evidence profile or workflow_call
  contract touched.

## Hygiene

- Do not commit generated project files, binaries, model weights, downloaded
  runtimes, sample media dumps, memory indexes, caches, IDE metadata, or build
  output.
- Keep raw stdout/stderr for tests and machine-readable CLI contracts; use
  openFrameworks logging conventions for addon runtime/example logging.
- Preserve openFrameworks-style public names and document intentional breaking
  changes.

## Validation

- Run the touched repository's local validation before handoff.
- For `ofxGgmlWorkflows`, run `scripts\validate-local.ps1` or
  `scripts\validate-local.bat`.
- For cross-repo work, report the Core planning/readiness command used and the
  validation commands that passed.
- Treat failed validation, stale planning output, missing caller scripts, or
  dirty target repositories as stop conditions until reviewed.
