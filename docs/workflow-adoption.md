# ofxGgml Workflow Adoption

This repository owns reusable GitHub Actions workflows for the managed
ofxGgml ecosystem. Companion repositories should consume these workflows with
`workflow_call` instead of copying policy logic into each addon.

## Adoption tiers

| Tier | Purpose | Workflows |
| --- | --- | --- |
| Required agent baseline | Keep Codex, GitHub Copilot, and Hermes Agent instructions present and current. | `coding-agent-instructions.yml` |
| Required addon hygiene | Check repository shape, metadata, generated artifact policy, and release basics. | `addon-hygiene.yml`, `metadata-validation.yml`, `release-check.yml` |
| Operational visibility | Feed Core planning, dashboards, and live status reports. | `live-workflow-status.yml`, `workflow-status-plan.yml`, `ecosystem-health.yml`, `ecosystem-health-report.yml` |
| Compatibility and release planning | Score release readiness and compare repository metadata across the family. | `baseline-compatibility.yml`, `compatibility-matrix.yml`, `metadata-reconciliation.yml`, `release-gate.yml`, `release-plan.yml`, `release-readiness-score.yml` |
| Runtime certification | Reserve backend and platform checks for lanes that can exercise the relevant runtime. | `backend-runtime-check.yml`, `backend-capability-report.yml`, `cross-repo-capability-map.yml`, `multi-platform-smoke.yml`, `of-smoke-build.yml`, `cuda-runtime-certification.yml`, `metal-runtime-certification.yml`, `vulkan-runtime-certification.yml` |
| Workflow repository self-checks | Validate this repository and its documentation. | `workflow-repo-validation.yml`, `ecosystem-docs.yml` |

## Caller pattern

Companion repositories should keep caller workflows small. The reusable
workflow should own the policy; the addon repository should only decide when
to run it and which inputs apply.

```yaml
name: coding-agent-instructions

on:
  push:
  pull_request:

jobs:
  instructions:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/coding-agent-instructions.yml@main
```

For non-addon repositories, disable addon-specific shape checks when the
reusable workflow exposes inputs for that purpose:

```yaml
jobs:
  instructions:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/coding-agent-instructions.yml@main
    with:
      require_addon_config: false
```

## Core coordination

`ofxGgmlCore` is the control-plane consumer for ecosystem planning. Core tools
expect workflow callers to stay aligned with these names:

- `scripts\audit-ecosystem.bat -Strict` checks managed repositories for agent
  instructions, validation entry points, release gates, and coding-agent
  workflow coverage.
- `scripts\check-ecosystem-readiness.bat -SkipDoctorTests` verifies that the
  planning layer can generate ecosystem plans, coding-agent work queues,
  doctor rollout plans, and branch cleanup plans.
- `scripts\fetch-workflow-status.py` can observe live workflow status without
  failing local planning when optional rollout workflows are not yet present.

## Rollout rules

- Prefer adding or updating one caller workflow per pull request.
- Keep reusable policy in `ofxGgmlWorkflows`; keep repository-specific commands
  in the caller repository.
- Treat backend certification workflows as lane-specific until the relevant
  addon can validate that backend locally.
- `backend-runtime-check.yml` runs CPU runtime smoke where platform-native
  scripts exist and uploads `build/runtime-smoke/backend-runtime-smoke.json`
  as non-source evidence.
- Do not use workflow updates as permission to change addon runtime/source
  behavior.
- Validate this repository with `scripts\validate-local.bat` before publishing
  reusable workflow changes.
