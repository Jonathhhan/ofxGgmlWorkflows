# Evidence Promotion Playbook

This playbook defines how a companion addon moves from visible evidence to
release-facing gates without changing Evidence Schema v1.

## Promotion Ladder

| Stage | Workflow profile | Meaning | Promotion requirement |
| --- | --- | --- | --- |
| `advisory-visible` | `evidence_profile=advisory` | Evidence may be absent or incomplete, but quality reports expose the gap. | Caller exists and uploads a quality report when evidence appears. |
| `schema-required` | `evidence_profile=schema` | Evidence file must exist and satisfy Evidence Schema v1. | At least one clean advisory run with schema-valid evidence. |
| `current-sha-required` | `evidence_profile=current-sha` | Evidence must match the commit under test. | Repeated schema-valid runs with stable `commit_sha` production. |
| `fresh-current-sha-required` | `evidence_profile=fresh-current-sha` | Evidence must be schema-valid, current, and recent. | Stable timestamps and agreed freshness window. |
| `release-gated` | `release_profile=release` | Release reports and evidence are both required. | Repeated fresh evidence plus generated release reports. |

`ofxGgmlWorkflows` owns the reusable gates and profile semantics.
`ofxGgmlCore` recommends promotion from ecosystem planning and evidence
aggregation. Companion addons own the scripts that produce model- or
lane-specific evidence.

## First Pilot

Use `ofxGgmlSam` as the first promotion pilot:

```powershell
scripts\run-sam3-evidence-pilot.bat -Backend cpu
```

The pilot writes:

```text
build/evidence/sam3-runtime-evidence.json
build/evidence/evidence-quality.md
```

The advisory caller should stay on `evidence_profile=advisory` until the pilot
has repeated clean local and CI evidence.

## Promotion Inputs

Before promoting, inspect the quality report and evidence records for:

- `schema_version`
- `commit_sha`
- `backend`
- `result`
- `timestamp`
- `artifact_path`
- `producer`
- `producer_version`
- `command_exit_code`
- `tree_state`
- `subject_paths`

Do not add required fields to Evidence Schema v1 just to support promotion
advice. Promotion recommendations should be reports or Core planning output.

## Stop Conditions

Stop promotion when:

- Core planning is stale or fails.
- The target repository is dirty with unrelated changes.
- Evidence exists but does not match the current commit.
- The advisory caller has not passed at least once.
- The caller references generated artifacts not produced in CI.
- Accelerator certification is requested without runner evidence.

## Next Mechanics

The next reusable workflow should be an advisory promotion report, not a gate:

```yaml
jobs:
  evidence-promotion:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/evidence-promotion-advisor.yml@main
    with:
      evidence_path: build/evidence/sam3-runtime-evidence.json
      current_profile: advisory
      candidate_profile: schema
      required_clean_runs: "3"
      minimum_quality_score: "85"
```

The report should recommend one of:

- stay advisory
- promote to schema
- promote to current-sha
- promote to fresh-current-sha
- ready for release-gate

Keep that recommendation separate from Evidence Schema v1 so the schema stays
neutral and reusable across companions.
