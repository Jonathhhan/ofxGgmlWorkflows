# Managed Addon Rollout Matrix

This matrix turns the current Core ecosystem plan into an all-addon rollout
queue. It is a planning artifact for workflow and evidence adoption, not
permission to edit addon runtime behavior.

Generated from:

```powershell
..\ofxGgmlCore\scripts\plan-ecosystem.ps1 -Json -SummaryOnly
```

## Summary

- Managed repositories present: 11
- Ready managed repositories: 9
- Dirty managed repositories: 2
- Missing managed repositories: 0
- Missing validation entrypoints: 0
- Missing doctor entrypoints: 0

## Ready Repositories

| Repository | First improvement | Initial rollout profile | Evidence/report path |
| --- | --- | --- | --- |
| `ofxGgmlCore` | Keep planning/readiness commands authoritative before fanout. | none | none |
| `ofxGgmlLlama` | Evidence writer ready (v1.0.0) -- quality 76.92% local, CI pending. | `evidence_profile=advisory` | `build/evidence/llama-runtime-evidence.json` |
| `ofxGgmlSam` | Evidence writer updated (v1.0.0) -- quality 92.31% in a CI simulation and 76.92% locally; real CI verification is pending. | `evidence_profile=advisory` | `build/evidence/sam3-runtime-evidence.json` |
| `ofxGgmlAudio` | Evidence writer ready (v1.0.0) -- quality 76.92% local, CI pending. | `evidence_profile=advisory` | `build/evidence/audio-runtime-evidence.json` |
| `ofxGgmlMusic` | Evidence writer ready (v1.0.0) -- quality 76.92% local, CI pending. | `evidence_profile=advisory` | `build/evidence/music-runtime-evidence.json` |
| `ofxGgmlVision` | Evidence writer ready (v1.0.0) -- quality 76.92% local, CI pending. | `evidence_profile=advisory` | `build/evidence/vision-runtime-evidence.json` |
| `ofxGgmlVideo` | Keep MontageAutomat handoff contracts validated before adding model-backed video evidence. | none | none |
| `ofxGgmlAgents` | Read-only allowlisted tool loop proven with a real local model; keep arbitrary filesystem, command, memory, and RAG tools out of scope until separately demonstrated. | none | none |
| `ofxGgmlWorkflows` | Keep reusable workflow fixtures, manifest coverage, and evidence policy aligned. | none | none |

## Dirty Repositories

Do not fan out workflow enforcement into dirty repositories until unrelated
changes are reviewed.

| Repository | Dirty count | Safe next step |
| --- | ---: | --- |
| `ofxGgmlStableDiffusion` | 8 | Review local changes before adding callers. |
| `ofxGgmlRag` | 9 | Review local changes before adding callers. |

## Reference Repositories

Keep classified legacy/reference siblings out of managed automation unless they
are explicitly promoted by Core planning:

- `ofxGgml`
- `ofxGgml##`
- `ofxGgml___`
- `ofxGgml______________`
- `ofxGgml_X`
- `ofxGgmlAAAA`
- `ofxGgmlDiffusion`
- `ofxGgmlXXX`

## SAM Pilot Status

The SAM evidence writer (`scripts/write-sam3-runtime-evidence.ps1`) has been
updated to v1.0.0 with improved quality coverage:

- **CI-simulated quality**: 92.31% (12/13 checks) -- exceeds the 85% quality threshold but does not satisfy the clean CI-run gate
- **Local quality**: 76.92% (10/13 checks) -- CI-only fields missing locally
- **Known gap**: `artifact_attestation` requires sigstore/slsa tooling
- **Next gate**: Push changes to `ofxGgmlSam` and verify CI workflows pass
- **Promotion path**: advisory -> schema (after repeated clean CI runs)


## Companion Evidence Writer Status

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

**Next gate**: Push companion addon changes to GitHub and verify CI workflows pass.
## Promotion Rules

- Start with advisory `evidence-validation.yml` callers.
- For the Sam pilot, follow `docs\sam-evidence-pilot-handoff.md` and emit
  Evidence Schema v1 JSON before adding the caller.
- Require schema-valid/current/fresh evidence only after repeated clean
  advisory runs.
- Require `of-smoke-build.yml` scripts only after a companion owns stable
  project generation, example build, and smoke evidence artifacts.
- Require `release-gate.yml` reports only after the caller generates the
  matching report paths.
- Keep CUDA, Metal, and Vulkan certification lane-specific until a repository
  has real self-hosted runner evidence.
- Re-run Core planning before each fanout batch and stop on dirty target repos,
  stale planning output, missing caller scripts, or failed local validation.
