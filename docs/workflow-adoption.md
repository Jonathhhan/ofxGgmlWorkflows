# ofxGgml Workflow Adoption

This repository owns reusable GitHub Actions workflows for the managed
ofxGgml ecosystem. Companion repositories should consume these workflows with
`workflow_call` instead of copying policy logic into each addon.

## Adoption tiers

| Tier | Purpose | Workflows |
| --- | --- | --- |
| Required agent baseline | Keep Codex, GitHub Copilot, and Hermes Agent instructions present and current. | `coding-agent-instructions.yml` |
| Required addon hygiene | Check repository shape, optional examples, metadata, feature promises, generated artifact policy, and release basics. | `addon-hygiene.yml`, `metadata-validation.yml`, `release-check.yml` |
| Operational visibility | Feed Core planning, dashboards, and live status reports. | `live-workflow-status.yml`, `workflow-status-plan.yml`, `ecosystem-health.yml`, `ecosystem-health-report.yml` |
| Compatibility and release planning | Score release readiness and compare repository metadata across the family. | `baseline-compatibility.yml`, `compatibility-matrix.yml`, `metadata-reconciliation.yml`, `release-gate.yml`, `release-plan.yml`, `release-readiness-score.yml` |
| Runtime certification | Reserve backend and platform checks for lanes that can exercise the relevant runtime. | `evidence-validation.yml`, `backend-runtime-check.yml`, `backend-capability-report.yml`, `cross-repo-capability-map.yml`, `multi-platform-smoke.yml`, `of-smoke-build.yml`, `cuda-runtime-certification.yml`, `metal-runtime-certification.yml`, `vulkan-runtime-certification.yml` |
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

For companion addons that should always ship runnable openFrameworks examples,
enable the optional examples check in the hygiene workflow:

```yaml
name: addon-hygiene

on:
  push:
  pull_request:

jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
    with:
      require_examples: true
```

For managed companion addons, make feature metadata a release-facing contract:

```yaml
name: addon-metadata

on:
  push:
  pull_request:

jobs:
  metadata:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/metadata-validation.yml@main
    with:
      require_metadata_file: true
      require_feature_metadata: true
      require_readme_features: true
```

For release coordination, keep report checks advisory until the caller can
generate the matching artifacts and evidence, then opt into required gates:

```yaml
name: release-gate

on:
  push:
  pull_request:

jobs:
  release-gate:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/release-gate.yml@main
    with:
      require_release_readiness_score: true
      require_metadata_reconciliation_report: true
      require_cross_repo_capability_map: true
      require_evidence_file: true
      require_evidence_schema_valid: true
      require_current_sha_evidence: true
```

For backend CPU runtime smoke, keep the reusable workflow advisory until the
caller carries platform-native setup scripts and emits runtime evidence:

```yaml
name: backend-runtime

on:
  push:
  pull_request:

jobs:
  backend-runtime:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/backend-runtime-check.yml@main
    with:
      require_runtime_smoke_source: true
      require_linux_runtime_smoke_script: true
      require_windows_runtime_smoke_scripts: true
      require_macos_runtime_smoke_script: true
      require_backend_runtime_smoke_evidence: true
```

For generator/report workflows, use advisory mode during rollout and opt into
both the script and artifact requirements once the caller owns the report:

```yaml
name: release-readiness-score

on:
  push:
  pull_request:

jobs:
  readiness:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/release-readiness-score.yml@main
    with:
      require_generator: true
      require_report_artifact: true
      report_artifact_path: docs/release-readiness-score.md
```

For build smoke workflows, keep reusable logic generic and require caller-owned
scripts only after that lane can build on the selected runner:

```yaml
name: of-smoke-build

on:
  push:
  pull_request:

jobs:
  smoke:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/of-smoke-build.yml@main
    with:
      require_examples: true
      require_project_generator_script: true
      require_example_build_script: true
      require_smoke_build_evidence: true
```

For accelerator certification, the reusable workflow should own truth semantics
and the caller should own backend-specific build commands:

```yaml
name: cuda-runtime-certification

on:
  push:
  pull_request:

jobs:
  cuda:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/cuda-runtime-certification.yml@main
    with:
      require_runtime_smoke_build_script: true
      runtime_smoke_build_script_path: scripts/ci-build-runtime-smoke.sh
      runtime_smoke_executable_path: build/runtime-smoke/runtime_smoke
      require_runtime_smoke_evidence: true
```

For evidence quality, adopt schema validation before promoting smoke or
certification artifacts into release gates:

```yaml
name: evidence-validation

on:
  push:
  pull_request:

jobs:
  evidence:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/evidence-validation.yml@main
    with:
      evidence_path: build/**/*.json
      require_evidence_file: false
      require_schema_valid: false
      require_current_sha: false
      minimum_certification_level: ""
      quality_report_path: build/evidence/evidence-quality.md
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
- Enable `require_examples` only after the companion addon has a top-level
  `examples/` or `example*` directory that should be release-maintained.
- Enable `require_feature_metadata` and `require_readme_features` together for
  managed addons once their `ofxggml-addon.json` feature list and README
  `## Features` section describe the same public promise.
- Enable `release-gate.yml` required report inputs only after the caller
  generates the corresponding report artifacts under `docs/`.
- Enable release evidence gates only after `evidence-validation.yml` has passed
  in advisory mode for the same evidence path.
- Enable `backend-runtime-check.yml` required smoke inputs only after the
  caller has platform-native setup scripts and writes backend runtime evidence.
- Enable generator/report `require_generator` and `require_report_artifact`
  together after the caller has the script and expected report path.
- For status/checker workflows, use their matching `require_fetcher` or
  `require_checker` input alongside `require_report_artifact`.
- For `ecosystem-docs.yml`, enable each per-document generator and artifact
  requirement only after that specific document is owned by the caller.
- For smoke build workflows, keep build commands in caller scripts and require
  smoke evidence only after those scripts produce stable JSON artifacts.
- For accelerator certification workflows, keep the self-hosted runner labels
  lane-specific and require caller build scripts before enforcing evidence.
- Enable `evidence-validation.yml` in advisory mode before making evidence
  required in release gates or backend certification workflows.
- Enable evidence freshness checks only after callers reliably write
  `commit_sha` and `timestamp` fields.
- Require backend/result/certification-level filters only after the caller
  produces at least one matching evidence record.
- Keep evidence policy changes in `scripts/validate-evidence.py` so
  `evidence-validation.yml` and `release-gate.yml` do not drift.
- Review the generated evidence quality report before promoting advisory
  evidence checks into required release gates.
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
