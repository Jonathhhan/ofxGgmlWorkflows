# ofxGgmlWorkflows

Reusable GitHub Actions workflows and policy templates for the ofxGgml addon ecosystem.

This repository centralizes lightweight automation for openFrameworks addons in the `ofxGgml` family.

## Workflows

All workflows are reusable via `workflow_call`. See [`docs/workflow-adoption.md`](docs/workflow-adoption.md) for adoption tiers, caller patterns, and Core coordination notes.

### Agent baseline

- `.github/workflows/coding-agent-instructions.yml` — verify `HERMES.md`, `AGENTS.md`, Copilot instructions, and ecosystem guardrails

### Addon hygiene

- `.github/workflows/addon-hygiene.yml` — check repository shape, governance files, and reject generated artifacts
- `.github/workflows/metadata-validation.yml` — validate addon metadata (requires `scripts/validate-addon-metadata.py` in caller)
- `.github/workflows/release-check.yml` — verify release metadata, docs, scripts, and reject release artifacts

### Operational visibility

- `.github/workflows/live-workflow-status.yml` — fetch live workflow status via GitHub API
- `.github/workflows/workflow-status-plan.yml` — generate workflow status plan
- `.github/workflows/ecosystem-health.yml` — verify manifest, docs, governance, and workflow inheritance
- `.github/workflows/ecosystem-health-report.yml` — generate ecosystem health report

### Compatibility and release planning

- `.github/workflows/baseline-compatibility.yml` — check baseline compatibility
- `.github/workflows/compatibility-matrix.yml` — generate compatibility matrix
- `.github/workflows/metadata-reconciliation.yml` — reconcile ecosystem metadata
- `.github/workflows/release-gate.yml` — gate release against required reports
- `.github/workflows/release-plan.yml` — generate release plan
- `.github/workflows/release-readiness-score.yml` — generate release readiness score

### Runtime certification

- `.github/workflows/backend-runtime-check.yml` — CPU runtime smoke across Linux, Windows, macOS
- `.github/workflows/backend-capability-report.yml` — generate backend capability report
- `.github/workflows/cross-repo-capability-map.yml` — generate cross-repo capability map
- `.github/workflows/multi-platform-smoke.yml` — multi-platform smoke build scaffold
- `.github/workflows/of-smoke-build.yml` — openFrameworks smoke build scaffold
- `.github/workflows/cuda-runtime-certification.yml` — CUDA runtime certification (self-hosted)
- `.github/workflows/metal-runtime-certification.yml` — Metal runtime certification (self-hosted)
- `.github/workflows/vulkan-runtime-certification.yml` — Vulkan runtime certification (self-hosted)

### Self-validation

- `.github/workflows/workflow-repo-validation.yml` — validate this repository on push/PR
- `.github/workflows/ecosystem-docs.yml` — generate ecosystem dashboard and docs

## Example

```yaml
name: addon-hygiene

on:
  push:
  pull_request:

jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
```

## Policy

The workflows enforce basic addon structure, artifact hygiene, and release readiness without requiring heavyweight native builds.

`coding-agent-instructions.yml` checks that consuming repositories carry
Hermes Agent `HERMES.md` project context, Codex-style `AGENTS.md` guidance, and
GitHub Copilot repository instructions plus
`.github/instructions/ofxggml-ecosystem.instructions.md` for focused Copilot
cloud agent and code review guardrails.

`workflow-repo-validation.yml` validates this repository's reusable workflow
templates on push and pull request.

## Adoption order

1. Add `coding-agent-instructions.yml` so Codex, GitHub Copilot, and Hermes
   Agent guidance stays present.
2. Add hygiene, metadata, and release checks before widening runtime behavior.
3. Add status and health workflows so `ofxGgmlCore` can observe ecosystem
   readiness.
4. Add runtime certification workflows only for lanes with relevant local
   validation.

## Validate

```powershell
scripts\validate-local.bat
```

On macOS/Linux:

```sh
./scripts/validate-local.sh
```

## Local Codex Profile

For local Codex runs with Qwen3.6-27B-Q4_0 on an RTX 3090, use
[docs/codex-qwen3-rtx3090-profile.md](docs/codex-qwen3-rtx3090-profile.md)
as the self-planning, self-optimizing, memory-aware operating baseline.