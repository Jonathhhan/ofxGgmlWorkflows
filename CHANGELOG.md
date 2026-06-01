# Changelog

All notable changes to ofxGgmlWorkflows are documented here.

## Unreleased

### Added

- `addon-hygiene.yml` now accepts `require_addon_config` and `require_src` inputs for non-addon repositories
- `addon-hygiene.yml` now accepts `require_examples` for companion addons that release-maintain examples
- `metadata-validation.yml` now accepts built-in metadata and README feature checks for managed addon feature promises
- `release-check.yml` now accepts `require_addon_config` input for non-addon repositories
- `release-gate.yml` now accepts required report inputs so callers can fail when release planning artifacts are missing
- `release-gate.yml` now accepts evidence schema, current-SHA, and freshness gates for release evidence
- `backend-runtime-check.yml` now accepts required smoke source, setup script, and evidence inputs for executable CPU runtime checks
- Generator/report workflows now accept `require_generator`, `require_report_artifact`, and `report_artifact_path` inputs for explicit soft-vs-required rollout
- `baseline-compatibility.yml` and `live-workflow-status.yml` now accept required checker/fetcher and report artifact inputs
- `ecosystem-docs.yml` now accepts per-document generator and artifact requirements for dashboard, compatibility, release plan, and PR fanout docs
- `multi-platform-smoke.yml` and `of-smoke-build.yml` now accept caller-owned script and smoke build evidence requirements
- CUDA, Metal, and Vulkan runtime certification workflows now accept caller-owned runtime smoke build scripts, executable paths, and evidence paths
- Added Evidence Schema v1 docs, JSON schema, and `evidence-validation.yml` for advisory-to-required evidence quality and freshness checks
- `evidence-validation.yml` and `release-gate.yml` can now require matching backend, result, and minimum certification level evidence
- Rewrote `scripts/workflow-metadata-extractor.ps1` with proper PowerShell syntax and YAML-aware metadata extraction
- Added `docs/codex-ecosystem-usage.md` with Codex ecosystem usage patterns and best practices
- `.gitignore` to prevent accidental commits of generated artifacts, model weights, build output, and IDE metadata
- Expanded README with full workflow catalog organized by adoption tier
- `CHANGELOG.md` to satisfy `release-check.yml` requirements

### Changed

- README now lists all 25 workflows grouped by adoption tier (agent baseline, addon hygiene, operational visibility, compatibility/release planning, runtime certification, self-validation)
- Local validation now checks every workflow file for UTF-8 BOMs
