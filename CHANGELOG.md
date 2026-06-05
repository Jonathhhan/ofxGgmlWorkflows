# Changelog

All notable changes to ofxGgmlWorkflows are documented here.

## Unreleased

### Added

- `addon-hygiene.yml` now accepts `require_addon_config` and `require_src` inputs for non-addon repositories
- `addon-hygiene.yml` now accepts `require_examples` for companion addons that release-maintain examples
- `metadata-validation.yml` now accepts built-in metadata and README feature checks for managed addon feature promises
- `release-check.yml` now accepts `require_addon_config` input for non-addon repositories
- `release-gate.yml` now accepts required report inputs so callers can fail when release planning artifacts are missing
- `release-gate.yml` now accepts configurable report paths for release readiness, metadata reconciliation, and capability map artifacts
- `release-gate.yml` now accepts evidence schema, current-SHA, and freshness gates for release evidence
- `backend-runtime-check.yml` now accepts required smoke source, setup script, and evidence inputs for executable CPU runtime checks
- Generator/report workflows now accept `require_generator`, `require_report_artifact`, and `report_artifact_path` inputs for explicit soft-vs-required rollout
- `baseline-compatibility.yml` and `live-workflow-status.yml` now accept required checker/fetcher and report artifact inputs
- `ecosystem-docs.yml` now accepts per-document generator and artifact requirements for dashboard, compatibility, release plan, and PR fanout docs
- `multi-platform-smoke.yml` and `of-smoke-build.yml` now accept caller-owned script and smoke build evidence requirements
- CUDA, Metal, and Vulkan runtime certification workflows now accept caller-owned runtime smoke build scripts, executable paths, and evidence paths
- Added Evidence Schema v1 docs, JSON schema, and `evidence-validation.yml` for advisory-to-required evidence quality and freshness checks
- Evidence Schema v1 now documents optional workflow provenance, runner context, dirty-tree disclosure, timing, producer, and artifact integrity fields
- `evidence-validation.yml` and `release-gate.yml` can now require matching backend, result, and minimum certification level evidence
- `evidence-validation.yml` now accepts `evidence_profile` and `release-gate.yml` now accepts `release_profile` for common advisory-to-required rollout modes
- Added `scripts/validate-evidence.py` so evidence validation and release gates share one implementation
- Added schema drift checks so Evidence Schema v1 and `scripts/validate-evidence.py` keep required fields and enums aligned
- Added `schemas/validation-manifest.json` and manifest checks for expected files, workflow inventory, evidence fixture inventory, workflow fixture inventory, advisory-vs-required fixture pairs, rollout profile allowlists, docs coverage, validator capability tokens, instruction hooks, self-validation hooks, and shared workflow pattern groups
- Added rollout profile checks so profile allowlists, fixture usage, and docs stay aligned
- Added fixture-based evidence validator contract tests for valid records, invalid optional fields, freshness, SHA, certification, and array records
- Added reusable workflow caller fixtures for advisory and required rollout modes, plus local fixture contract validation
- Strengthened reusable workflow caller fixture validation to assert advisory-vs-required input semantics
- Added `docs/agent-handoff-contract.md` for cross-repo workflow rollout, evidence promotion, release planning, and companion PR fanout handoffs
- Added `docs/agent-baseline.md` as the shared Hermes, Codex, and Copilot operating baseline
- Added `docs/hermes-openframeworks-ggml-skills.md` to teach agents the openFrameworks addon loop, ggml runtime ownership split, evidence expectations, and generated artifact hygiene
- Added `docs/hermes-ecosystem-learning-plan.md` for Hermes instruction, RAG/memory, skill, and evaluation layers before fine-tuning or broad automation
- Added `docs/managed-addon-rollout.md` with the current ready/dirty repository matrix and advisory-first all-addon rollout queue
- Added `docs/sam-evidence-pilot-handoff.md` to define the Sam CPU evidence wrapper contract before advisory caller rollout
- Added `docs/evidence-promotion-playbook.md` with the advisory-visible to release-gated promotion ladder
- Added `evidence-promotion-advisor.yml` and local advisor tests for advisory evidence promotion reports
- Updated the ecosystem roadmap with the current all-addon improvement queue, ready repositories, dirty-repo stop conditions, and reference-repo exclusions
- Refreshed rollout and roadmap docs with the current Core planning dirty/ready matrix
- Strengthened `coding-agent-instructions.yml` to verify lane, Core planning, companion-boundary, artifact-hygiene, validation, and handoff guardrails
- Evidence validation can now write an advisory quality report for evidence completeness before stricter gates are enabled
- Rewrote `scripts/workflow-metadata-extractor.ps1` with proper PowerShell syntax and YAML-aware metadata extraction
- Added `docs/codex-ecosystem-usage.md` with Codex ecosystem usage patterns and best practices
- Added `docs/future-ecosystem-roadmap.md` with the pilot-first ecosystem roadmap from agent review
- `.gitignore` to prevent accidental commits of generated artifacts, model weights, build output, and IDE metadata
- Expanded README with full workflow catalog organized by adoption tier
- `CHANGELOG.md` to satisfy `release-check.yml` requirements

### Changed

- README now lists all 26 workflows grouped by adoption tier (agent baseline, addon hygiene, operational visibility, compatibility/release planning, runtime certification, self-validation)
- `evidence-validation.yml` and `release-gate.yml` now run `validate-evidence.py` from a pinned `ofxGgmlWorkflows` tools checkout instead of requiring caller repositories to carry the validator script
- Local validation now checks every workflow file for UTF-8 BOMs
