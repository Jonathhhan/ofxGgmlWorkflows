# ofxGgmlWorkflows

Reusable GitHub Actions workflows and policy templates for the ofxGgml addon ecosystem.

This repository centralizes lightweight automation for openFrameworks addons in the `ofxGgml` family.

## Workflows

All workflows are reusable via `workflow_call`. See [`docs/workflow-adoption.md`](docs/workflow-adoption.md) for adoption tiers, caller patterns, and Core coordination notes.
See [`docs/future-ecosystem-roadmap.md`](docs/future-ecosystem-roadmap.md) for
the current pilot-first ecosystem roadmap.

### Agent baseline

- `.github/workflows/coding-agent-instructions.yml` - verify `HERMES.md`, `AGENTS.md`, Copilot instructions, and ecosystem guardrails

### Addon hygiene

- `.github/workflows/addon-hygiene.yml` - check repository shape, optional examples, governance files, and generated artifact policy
- `.github/workflows/metadata-validation.yml` - validate addon metadata, feature promises, README feature coverage, and optional caller validators
- `.github/workflows/release-check.yml` - verify release metadata, docs, scripts, and reject release artifacts

### Operational visibility

- `.github/workflows/live-workflow-status.yml` - fetch live workflow status via GitHub API
- `.github/workflows/workflow-status-plan.yml` - generate workflow status plan
- `.github/workflows/ecosystem-health.yml` - verify manifest, docs, governance, and workflow inheritance
- `.github/workflows/ecosystem-health-report.yml` - generate ecosystem health report

### Compatibility and release planning

- `.github/workflows/baseline-compatibility.yml` - check baseline compatibility
- `.github/workflows/compatibility-matrix.yml` - generate compatibility matrix
- `.github/workflows/metadata-reconciliation.yml` - reconcile ecosystem metadata
- `.github/workflows/release-gate.yml` - gate release against required reports
- `.github/workflows/release-plan.yml` - generate release plan
- `.github/workflows/release-readiness-score.yml` - generate release readiness score

### Runtime certification

- `.github/workflows/evidence-validation.yml` - validate neutral evidence JSON artifacts against Evidence Schema v1
- `.github/workflows/backend-runtime-check.yml` - CPU runtime smoke across Linux, Windows, macOS
- `.github/workflows/backend-capability-report.yml` - generate backend capability report
- `.github/workflows/cross-repo-capability-map.yml` - generate cross-repo capability map
- `.github/workflows/multi-platform-smoke.yml` - multi-platform smoke build contract
- `.github/workflows/of-smoke-build.yml` - openFrameworks example smoke build contract
- `.github/workflows/cuda-runtime-certification.yml` - CUDA runtime certification (self-hosted)
- `.github/workflows/metal-runtime-certification.yml` - Metal runtime certification (self-hosted)
- `.github/workflows/vulkan-runtime-certification.yml` - Vulkan runtime certification (self-hosted)

### Self-validation

- `.github/workflows/workflow-repo-validation.yml` - validate this repository on push/PR
- `.github/workflows/ecosystem-docs.yml` - generate ecosystem dashboard and docs

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

For non-addon repositories, disable addon-specific checks:

```yaml
jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
    with:
      require_addon_config: false
      require_src: false
```

For companion addons where examples are part of release readiness, opt into
the example-directory check:

```yaml
jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
    with:
      require_examples: true
```

To protect ecosystem feature promises, enable built-in metadata and README
feature checks:

```yaml
jobs:
  metadata:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/metadata-validation.yml@main
    with:
      require_metadata_file: true
      require_feature_metadata: true
      require_readme_features: true
```

To make the release gate enforce generated ecosystem reports, opt into the
required report and evidence checks that apply to the caller:

```yaml
jobs:
  release-gate:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/release-gate.yml@main
    with:
      require_release_readiness_score: true
      release_readiness_score_path: docs/release-readiness-score.md
      require_metadata_reconciliation_report: true
      metadata_reconciliation_report_path: docs/metadata-reconciliation-report.md
      require_cross_repo_capability_map: true
      cross_repo_capability_map_path: docs/cross-repo-capability-map.md
      require_evidence_file: true
      require_evidence_schema_valid: true
      require_current_sha_evidence: true
```

To make backend CPU runtime smoke checks executable instead of advisory, require
the caller's platform-native smoke setup scripts and evidence artifact:

```yaml
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

Generator/report workflows can also move from advisory to required once the
caller owns the generator script and output artifact. The release gate uses
matching configurable report paths so callers can keep generated docs in their
own stable locations:

```yaml
jobs:
  readiness:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/release-readiness-score.yml@main
    with:
      require_generator: true
      require_report_artifact: true
      report_artifact_path: docs/release-readiness-score.md
```

`ecosystem-docs.yml` exposes per-document requirements so callers can harden
dashboard, compatibility, release plan, and PR fanout generation independently.

Smoke build workflows can stay structural during rollout, then require caller
scripts and evidence artifacts once a lane owns real build execution:

```yaml
jobs:
  smoke:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/of-smoke-build.yml@main
    with:
      require_examples: true
      require_project_generator_script: true
      require_example_build_script: true
      require_smoke_build_evidence: true
```

Accelerator certification workflows stay strict about running `runtime_smoke`,
but callers can now provide the build script, executable path, and evidence path:

```yaml
jobs:
  cuda-certification:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/cuda-runtime-certification.yml@main
    with:
      require_runtime_smoke_build_script: true
      runtime_smoke_build_script_path: scripts/ci-build-runtime-smoke.sh
      runtime_smoke_executable_path: build/runtime-smoke/runtime_smoke
      require_runtime_smoke_evidence: true
```

Evidence artifacts can be validated in advisory mode first, then promoted to a
required schema contract once a companion addon writes stable JSON:

```yaml
jobs:
  evidence:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/evidence-validation.yml@main
    with:
      evidence_path: build/**/*.json
      require_evidence_file: true
      require_schema_valid: true
      require_current_sha: true
      required_backend: cuda
      required_result: pass
      minimum_certification_level: runtime-certified
      quality_report_path: build/evidence/evidence-quality.md
```

See [docs/evidence-schema-v1.md](docs/evidence-schema-v1.md) for the required
fields, optional certification fields, and ownership split. Both
`evidence-validation.yml` and `release-gate.yml` use
`scripts/validate-evidence.py` so advisory checks and release gates share one
evidence validation implementation. The validator also writes an advisory
quality report so weak evidence is visible before stricter gates are enabled.

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
4. Add evidence validation before widening smoke or runtime certification.
5. Add runtime certification workflows only for lanes with relevant local
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
