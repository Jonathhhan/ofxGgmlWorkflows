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
| `ofxGgmlLlama` | Add advisory evidence validation after the Sam CPU pilot is stable. | `evidence_profile=advisory` | `build/**/*.json` |
| `ofxGgmlSam` | Keep SAM3 CPU evidence validation and promotion advice advisory until repeated clean runs are reviewed. | `evidence_profile=advisory` | `build/evidence/sam3-runtime-evidence.json` |
| `ofxGgmlAudio` | Add advisory evidence validation after the Sam CPU pilot is stable. | `evidence_profile=advisory` | `build/**/*.json` |
| `ofxGgmlMusic` | Separate readiness, model-load, and generation evidence before stricter MusicGen or AceStep gates. | `evidence_profile=advisory` | `build/**/*.json` |
| `ofxGgmlVision` | Add advisory evidence validation after the Sam CPU pilot is stable. | `evidence_profile=advisory` | `build/**/*.json` |
| `ofxGgmlVideo` | Keep MontageAutomat handoff contracts validated before adding model-backed video evidence. | none | none |
| `ofxGgmlAgents` | Validate planning and handoff records before enabling autonomous runtime behavior. | none | none |
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
