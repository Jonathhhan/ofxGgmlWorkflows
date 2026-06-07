# ofxGgmlWorkflows

Reusable GitHub Actions workflows and policy templates for the ofxGgml addon ecosystem.

This repository centralizes lightweight automation for openFrameworks addons in the `ofxGgml` family.

## Workflows

All workflows are reusable via `workflow_call`. See [`docs/workflow-adoption.md`](docs/workflow-adoption.md) for adoption tiers, caller patterns, and Core coordination notes.
See [`docs/future-ecosystem-roadmap.md`](docs/future-ecosystem-roadmap.md) for
the current pilot-first ecosystem roadmap.
See [`docs/managed-addon-rollout.md`](docs/managed-addon-rollout.md) for the
current ready/dirty repository matrix and all-addon rollout queue.
Use [`docs/sam-evidence-pilot-handoff.md`](docs/sam-evidence-pilot-handoff.md)
for the first Evidence Schema v1 companion rollout contract.
Use [`docs/evidence-promotion-playbook.md`](docs/evidence-promotion-playbook.md)
for the advisory-to-release evidence promotion ladder.
Use [`docs/workflow-release-policy.md`](docs/workflow-release-policy.md) for
`@main`, `v1`, immutable patch tag, Dependabot, and SHA-pinning rollout policy.
Use [`docs/agent-handoff-contract.md`](docs/agent-handoff-contract.md) when
passing cross-repo rollout, evidence promotion, release planning, or companion
PR fanout work between agents.
Use [`docs/agent-baseline.md`](docs/agent-baseline.md) as the canonical
Hermes/Codex/Copilot baseline that local instruction files should mirror.
Use [`docs/hermes-openframeworks-ggml-skills.md`](docs/hermes-openframeworks-ggml-skills.md)
to teach Hermes and sibling agents the openFrameworks addon loop, ggml runtime
ownership split, evidence expectations, and generated artifact hygiene.
Use [`docs/hermes-source-learning-map.md`](docs/hermes-source-learning-map.md)
when Hermes should learn from upstream sources such as `ggml-org`,
`stable-diffusion.cpp`, and `openFrameworks` before changing local provider,
companion, or addon-layout contracts. Use
`scripts\plan-hermes-source-learning.ps1 -Json` to generate an agent-ready
source-learning retrieval packet.
Use [`docs/hermes-ecosystem-learning-plan.md`](docs/hermes-ecosystem-learning-plan.md)
for Hermes instruction, RAG/memory, skill, and evaluation layers before
fine-tuning or broad agent automation.
Use [`docs/hermes-agent-operating-loop.md`](docs/hermes-agent-operating-loop.md)
as the action loop for lane classification, retrieval packets, stop
conditions, validation, and handoff shape.
Use [`docs/hermes-multi-agent-improvement.md`](docs/hermes-multi-agent-improvement.md)
and `scripts\plan-hermes-agent-improvement.ps1 -Json` when using subagents or
sibling agents to improve agent instructions, memory, evals, or operating-loop
behavior. The planner emits specialized role profiles and addon lane briefs;
use `-Focus addon-fanout` for one-agent-per-addon review planning. Each profile
also includes a `prompt_packet` for consistent sidecar launch prompts. The
planner exposes a `prompt_launch_queue` when Hermes needs launchable work items.
Use `-PromptQueue -Json` for a compact queue-only output that includes the
read-first files, question, output contract, stop conditions, and prompt text,
with `-QueueType` or `-QueueId` to select a specific work item.
The planner tracks `NousResearch/hermes-agent` and `openai/codex` as source-learning
references for agent loops, memory, skills, local validation, and handoff
discipline without vendoring external code.
Use [`docs/hermes-memory-contract.md`](docs/hermes-memory-contract.md)
with `scripts\write-hermes-memory-index.ps1` and
`scripts\check-hermes-memory-index.ps1` when Hermes needs durable,
source-grounded memory with file hashes and timestamps that can be refreshed,
checked, and validated before repository work.
Use [`docs/hermes-openframeworks-ggml-evals.md`](docs/hermes-openframeworks-ggml-evals.md)
as the prompt-only eval pack before giving Hermes broader repository authority.
Use [`docs/hermes-openframeworks-ggml-evals.json`](docs/hermes-openframeworks-ggml-evals.json)
when an agent or dashboard needs the same scenarios in machine-readable form.

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
- `.github/workflows/workflow-security-advice.yml` - generate report-only workflow hardening advice for explicit permissions and SHA pinning

### Compatibility and release planning

- `.github/workflows/baseline-compatibility.yml` - check baseline compatibility
- `.github/workflows/compatibility-matrix.yml` - generate compatibility matrix
- `.github/workflows/metadata-reconciliation.yml` - reconcile ecosystem metadata
- `.github/workflows/release-gate.yml` - gate release against required reports
- `.github/workflows/release-plan.yml` - generate release plan
- `.github/workflows/release-readiness-score.yml` - generate release readiness score

### Runtime certification

- `.github/workflows/evidence-validation.yml` - validate neutral evidence JSON artifacts against Evidence Schema v1
- `.github/workflows/evidence-promotion-advisor.yml` - recommend advisory-to-required evidence promotion from evidence quality and clean-run inputs
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

Managed companion addons can also opt into stricter openFrameworks and ggml
boundary checks once their metadata and examples are stable:

```yaml
jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
    with:
      require_addon_metadata: true
      require_core_dependency: true
      require_example_core_dependency: true
      forbidden_addon_dependencies: "ofxGgmlAudio ofxGgmlMusic ofxGgmlVideo"
      reject_generated_project_files: true
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
      release_profile: release
      release_readiness_score_path: docs/release-readiness-score.md
      metadata_reconciliation_report_path: docs/metadata-reconciliation-report.md
      cross_repo_capability_map_path: docs/cross-repo-capability-map.md
      max_evidence_age_hours: "24"
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

Workflow security advice stays report-only during rollout. Use it to inventory
jobs missing explicit `permissions:` and external actions that still use tag
refs before relying on Dependabot coverage or making SHA pinning required:

```yaml
jobs:
  workflow-security:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/workflow-security-advice.yml@main
    with:
      recommended_consumer_ref: v1
      report_artifact_path: docs/workflow-security-advice.md
      require_explicit_permissions: true
      require_pinned_actions: false
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
      evidence_profile: current-sha
      required_backend: cuda
      required_result: pass
      minimum_certification_level: runtime-certified
      quality_report_path: build/evidence/evidence-quality.md
```

`evidence_profile` accepts `custom`, `advisory`, `schema`, `current-sha`,
`fresh-current-sha`, `certification`, and `release`. `release_profile` accepts
`custom`, `advisory`, `reports`, `evidence`, and `release`. The workflows print
the resolved enforcement inputs before running checks; `custom` preserves the
individual boolean inputs for callers that need exact control, including
`require_release_readiness_score`, `require_evidence_schema_valid`,
`require_schema_valid`, and `require_current_sha`.

See [docs/evidence-schema-v1.md](docs/evidence-schema-v1.md) for the required
fields, optional certification fields, and ownership split. Both
`evidence-validation.yml` and `release-gate.yml` use
`scripts/validate-evidence.py` from this workflow repository checkout so caller
repositories do not need to vendor policy scripts. Advisory checks and release
gates share one evidence validation implementation. The validator also writes
an advisory quality report so weak evidence is visible before stricter gates
are enabled. Evidence records can include `artifact_digest`,
`attestation_subject_digest`, `attestation_bundle_path`, and
`attestation_verified` so uploaded reports and release artifacts can carry
GitHub artifact digest and attestation provenance before those claims become
hard release gates.
For upload-capable reusable workflows, callers can also read the
`artifact_digest` workflow output when the underlying `actions/upload-artifact`
step emits its `artifact-digest` output. Matrix workflows expose per-runner
upload step IDs instead of a single collapsed digest because each OS produces
its own artifact.

## Policy

The workflows enforce basic addon structure, artifact hygiene, and release readiness without requiring heavyweight native builds.

`.github/dependabot.yml` enables weekly GitHub Actions update PRs for this
workflow repository. Keep those updates reviewed before promoting external
actions from tag refs to full commit SHAs.

`coding-agent-instructions.yml` checks that consuming repositories carry
Hermes Agent `HERMES.md` project context, Codex-style `AGENTS.md` guidance, and
GitHub Copilot repository instructions plus
`.github/instructions/ofxggml-ecosystem.instructions.md` for focused Copilot
cloud agent and code review guardrails. The reusable check also verifies core
ecosystem concepts: lane ownership, Core planning/shared-base ownership,
companion boundaries, generated artifact hygiene, validation, and handoff
guidance.

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

Local validation includes Evidence Schema v1 drift checks, evidence validator
fixtures, evidence promotion advisor tests, validation manifest checks, rollout
profile checks, Hermes memory index and readiness checks, Hermes agent and
source-learning plan checks, and reusable workflow caller fixtures under
`tests/workflows/` so representative advisory and required caller YAML stays
aligned with the reusable workflow inputs. Local validation also checks
Dependabot GitHub Actions coverage and the workflow security advice report
generator. The manifest in
`schemas/validation-manifest.json` owns
inventory-style validation such as expected files, workflow files, evidence
fixture files, workflow fixture files, advisory-vs-required fixture pairs,
rollout profile allowlists, docs coverage tokens, validator capability tokens,
instruction hooks, self-validation hooks, Hermes memory hooks, and shared
workflow pattern groups.

On macOS/Linux:

```sh
./scripts/validate-local.sh
```

## Local Codex Profile

For local Codex runs with Qwen3.6-27B-Q4_0 on an RTX 3090, use
[docs/codex-qwen3-rtx3090-profile.md](docs/codex-qwen3-rtx3090-profile.md)
as the self-planning, self-optimizing, memory-aware operating baseline.
