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
clean advisory runs.

## Stop Conditions

- Core planning is stale or fails.
- `ofxGgmlSam` becomes dirty with unrelated changes.
- The companion has no schema-compatible evidence producer.
- The evidence wrapper omits required Evidence Schema v1 fields.
- The workflow caller references generated files that are not produced in CI.
