# Sam Evidence Pilot Handoff

This handoff describes the first companion-addon rollout target for managed
Evidence Schema v1 adoption. It is a Workflows planning artifact, not permission
to edit `ofxGgmlSam` runtime behavior.

## Scope

- Target addon: `ofxGgmlSam`
- Pilot lane: CPU point segmentation smoke evidence
- Example target: `ofxGgmlSamPointExample`
- Initial workflow profile: `evidence_profile=advisory`
- Required reusable workflow before promotion: `evidence-validation.yml`
- Future promotion candidate: `of-smoke-build.yml` only after stable script and
  evidence output ownership exists in `ofxGgmlSam`

## Current Discovery

`ofxGgmlSam` currently has a clean worktree and owns local SAM3 runtime smoke
scripts. Its `.sam3-runtime-smoke.json` output is useful addon-specific smoke
data, but it is not Evidence Schema v1.

Do not point `evidence-validation.yml` at `.sam3-runtime-smoke.json` as if it
were schema evidence. Add a small companion-owned converter or producer first.

## Evidence Wrapper Contract

The pilot should emit a neutral evidence wrapper such as:

```text
build/evidence/sam3-runtime-evidence.json
```

The wrapper must satisfy `schemas/evidence-v1.schema.json` and include at least:

- `schema_version`
- `repo`
- `lane`
- `commit_sha`
- `workflow_name`
- `runner_os`
- `backend`
- `result`
- `timestamp`
- `artifact_path`

Recommended optional fields for this pilot:

- `example_name`
- `certification_level`
- `dirty_tree`
- `producer`
- `duration_ms`
- `quality_report_path`

Keep SAM-specific metrics, such as mask count, model path, image size, and
segment timings, in an addon-owned nested object or sidecar artifact. The
Evidence Schema v1 wrapper should stay neutral enough for Core dashboards and
Workflows gates.

## Evidence Writer Status

The evidence writer (`scripts/write-sam3-runtime-evidence.ps1`) has been updated
with four new capability groups:

- **`tool_versions`**: Object containing PowerShell version, ggml backend, and
  producer info. Populated via `Get-ToolVersions` helper.
- **`device_summary`**: CPU/device string like `"Windows x86_64 (20 logical
  processors)"` via .NET `[Environment]::ProcessorCount`.
- **Timing fields**: `started_at` / `completed_at` ISO timestamps capturing
  evidence generation timing.
- **CI workflow provenance**: `workflow_run_id`, `workflow_run_attempt`,
  `workflow_ref`, `workflow_sha`, `job_name`, `event_name`, `runner_labels` --
  conditionally included only when `GITHUB_*` / `RUNNER_LABELS` env vars are
  set. This avoids `null` validation errors on local runs.

## Quality Score Results

| Environment | Quality Score | Checks Passed | Missing Checks |
| --- | --- | --- | --- |
| Local run | 76.92% | 10/13 | `workflow_provenance`, `runner_context`, `artifact_attestation` |
| CI-simulated run | **92.31%** | 12/13 | `artifact_attestation` |

The CI-simulated quality score **exceeds the 85% quality threshold**, but it
does not satisfy the clean CI-run gate for advancing from advisory to schema
promotion. The remaining gap (`artifact_attestation`) requires sigstore/slsa
supply-chain tooling and is an acceptable gap for the advisory stage.

**Known gaps:**

- `artifact_attestation`: Requires sigstore/slsa signing tooling. Not expected
  at advisory stage; target for future supply-chain hardening.
- `commit_sha` shows `"unknown"` for local runs without a git HEAD; CI populates
  the real SHA.

## Advisory Caller Shape

After `ofxGgmlSam` owns schema-compatible evidence, add an advisory caller:

```yaml
name: evidence-validation

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  evidence:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/evidence-validation.yml@main
    with:
      evidence_path: build/evidence/sam3-runtime-evidence.json
      evidence_profile: advisory
      quality_report_path: build/evidence/evidence-quality.md
```

Promote to `schema`, `current-sha`, or `fresh-current-sha` only after repeated
clean advisory runs. The promotion advisor
(`evidence-promotion-advisor.yml`) requires 85% minimum quality score before
recommending schema promotion.

## Stop Conditions

- Core planning is stale or fails.
- `ofxGgmlSam` becomes dirty with unrelated changes.
- The companion has no schema-compatible evidence producer.
- The evidence wrapper omits required Evidence Schema v1 fields.
- The workflow caller references generated files that are not produced in CI.
- CI evidence-validation workflow fails after pushing updated evidence writer.

## Companion Evidence Writer Rollout

Evidence writers for the four clean companion addons follow the SAM Evidence Pilot
pattern (Evidence Schema v1). All writers produce 76.92% quality locally
(10/13 checks) with CI-provenance fields expected to raise scores to 92.31%+ in CI.

| Addon | Writer script | Evidence output | Local quality | CI quality | Status |
| --- | --- | --- | --- | --- | --- |
| `ofxGgmlLlama` | `scripts/write-llama-runtime-evidence.ps1` | `build/evidence/llama-runtime-evidence.json` | 76.92% | pending | writer ready |
| `ofxGgmlAudio` | `scripts/write-audio-runtime-evidence.ps1` | `build/evidence/audio-runtime-evidence.json` | 76.92% | pending | writer ready |
| `ofxGgmlMusic` | `scripts/write-music-runtime-evidence.ps1` | `build/evidence/music-runtime-evidence.json` | 76.92% | pending | writer ready |
| `ofxGgmlVision` | `scripts/write-vision-runtime-evidence.ps1` | `build/evidence/vision-runtime-evidence.json` | 76.92% | pending | writer ready |

**Known gaps** (all companions): `workflow_provenance`, `runner_context`, and
`artifact_attestation` are missing locally; these populate in GitHub Actions CI.
`artifact_attestation` requires sigstore/slsa tooling.

**Vision-specific notes**: smoke script lacks `InferenceChecked` and `SmokeKind`
fields; evidence writer hardcodes `inference_checked = $false` and
`smoke_kind = "metadata-only"`. Smoke currently fails on CMake but produces a
valid Summary object. `certification_level` is `"smoke-built"` on pass.

**Next gate**: Push companion addon changes to GitHub and verify CI evidence-validation
workflows hit 92.31%+ quality, then follow the same promotion path as SAM.