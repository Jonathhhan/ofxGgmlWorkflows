# Evidence Schema v1

Evidence artifacts are JSON files that let `ofxGgmlCore` and reusable
workflows reason about build, runtime, certification, and release-readiness
claims without knowing addon-specific implementation details.

The v1 schema is intentionally small. Unknown fields are allowed so companion
addons can include lane-specific details while the ecosystem stabilizes.

Freshness is checked by the reusable workflow, not by the schema itself. The
schema requires `commit_sha` and `timestamp` so callers can later opt into
current-SHA and max-age validation.

## Required Fields

| Field | Purpose |
| --- | --- |
| `schema_version` | Schema version. Use `1` or `"1"`. |
| `repo` | Repository or addon name that produced the evidence. |
| `lane` | Ecosystem lane, such as `core`, `workflow`, `companion`, or `runtime-backend`. |
| `commit_sha` | Git commit SHA the evidence was generated from. |
| `workflow_name` | Workflow or local validation name that produced the evidence. |
| `runner_os` | Runner operating system or local platform label. |
| `backend` | Backend or scope, such as `cpu`, `cuda`, `metal`, `vulkan`, `docs`, or `release`. |
| `result` | One of `pass`, `fail`, `skipped`, or `not_certified`. |
| `timestamp` | ISO 8601 date-time for evidence generation. |
| `artifact_path` | Path to the evidence or report artifact inside the repository or workflow run. |

## Optional Fields

| Field | Purpose |
| --- | --- |
| `command` | Command used to produce the result. |
| `certification_level` | One of `declared`, `smoke-built`, `runtime-certified`, or `release-gated`. |
| `tool_versions` | Object containing compiler, ggml, openFrameworks, backend, or script versions. |
| `device_summary` | Redacted or generic device information for hardware-backed runs. |
| `reason_code` | Reason for `skipped` or `not_certified` evidence. |
| `workflow_run_id`, `workflow_run_attempt`, `workflow_ref`, `workflow_sha`, `job_name` | Workflow provenance for the run that produced the evidence. |
| `matrix_os`, `runner_labels`, `event_name` | Runner and event context for interpreting CI evidence. |
| `producer`, `producer_version` | Evidence generator name and version. |
| `command_exit_code`, `started_at`, `completed_at` | Command result and timing details. |
| `tree_state` | One of `clean`, `dirty`, `generated-only`, or `unknown`. |
| `base_commit_sha`, `working_tree_patch_hash`, `untracked_count` | Optional dirty-tree disclosure for advisory evidence. |
| `artifact_sha256`, `subject_paths` | Artifact integrity and subject path hints for future trust gates. |

## Example

```json
{
  "schema_version": "1",
  "repo": "ofxGgmlSam",
  "lane": "companion",
  "commit_sha": "0123456789abcdef0123456789abcdef01234567",
  "workflow_name": "of-smoke-build",
  "runner_os": "Windows",
  "backend": "cpu",
  "result": "pass",
  "timestamp": "2026-06-02T01:30:00Z",
  "artifact_path": "build/of-smoke/of-smoke-build.json",
  "command": "scripts/ci-build-of-examples.sh",
  "command_exit_code": 0,
  "started_at": "2026-06-02T01:24:00Z",
  "completed_at": "2026-06-02T01:30:00Z",
  "certification_level": "smoke-built",
  "workflow_run_id": "123456789",
  "workflow_run_attempt": "1",
  "workflow_ref": "Jonathhhan/ofxGgmlSam/.github/workflows/of-smoke-build.yml@main",
  "workflow_sha": "0123456789abcdef0123456789abcdef01234567",
  "job_name": "of-smoke-build",
  "tree_state": "clean",
  "subject_paths": [
    "examples/ofxGgmlSamPointExample"
  ],
  "tool_versions": {
    "openframeworks": "0.12.x",
    "ggml": "local"
  }
}
```

## Ownership

- `ofxGgmlWorkflows` owns schema documentation, reusable validation workflows,
  artifact upload contracts, and opt-in enforcement switches.
- `ofxGgmlCore` owns ecosystem aggregation, dashboarding, freshness policy, and
  release-train interpretation.
- Companion addons own the scripts that generate evidence and any model- or
  backend-specific fields.

## Freshness Checks

`evidence-validation.yml` can validate freshness in stages:

- `require_current_sha` checks each evidence `commit_sha` against the workflow
  commit SHA or an explicit `expected_commit_sha`.
- `require_freshness` checks each evidence `timestamp` against
  `max_evidence_age_hours`.

Keep both disabled during first adoption. Enable them only after the caller's
evidence generator consistently writes commit and timestamp metadata.

## Certification Level Checks

`certification_level` has ordered semantics:

| Level | Meaning |
| --- | --- |
| `declared` | The addon declares support or intent, but no build/runtime proof is attached. |
| `smoke-built` | A smoke build or example build completed and produced evidence. |
| `runtime-certified` | A backend runtime check executed with required backend semantics. |
| `release-gated` | The evidence passed release-facing gates for the target commit. |

`evidence-validation.yml` can require at least one evidence record matching a
backend, result, and minimum certification level. `release-gate.yml` exposes the
same filter for release-facing evidence.

## Quality Reports

`scripts/validate-evidence.py` can write an advisory Markdown quality report.
The report scores whether evidence includes the fields that make future gates
trustworthy: schema core fields, current SHA, freshness, backend/result/level
matches, command, tool versions, device summary, artifact path, workflow
provenance, runner context, producer version, command result, timing,
tree-state disclosure, and artifact integrity hints.

Quality scores are informational. Use them to improve evidence generators before
turning on required schema, freshness, or release-gate inputs.
