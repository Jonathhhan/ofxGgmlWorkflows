# Future Ecosystem Roadmap

This roadmap captures the current Hermes-style ecosystem review for
ofxGgmlWorkflows. It is a planning artifact, not permission to edit companion
addon source.

For the concrete current repository queue, see
`docs\managed-addon-rollout.md`.

## Current Status

- `ofxGgmlWorkflows` owns reusable `workflow_call` contracts, policy checks,
  evidence validation, and automation docs. It is clean in the latest Core
  planning pass.
- `ofxGgmlCore` remains the shared base and ecosystem planning/dashboard
  control plane.
- Companion addons own backend-specific scripts, model-specific UX, and
  evidence generation.
- Core planning currently recommends making one backend lane genuinely useful
  before broadening automation across all companions.
- Dirty managed repositories should be reviewed before fanout enforcement:
  `ofxGgmlStableDiffusion` and `ofxGgmlRag`.
- Ready managed repositories are `ofxGgmlCore`, `ofxGgmlLlama`,
  `ofxGgmlSam`, `ofxGgmlAudio`, `ofxGgmlMusic`, `ofxGgmlVision`,
  `ofxGgmlVideo`, `ofxGgmlAgents`, and `ofxGgmlWorkflows`.
- Classified legacy/reference siblings should stay out of managed automation
  unless explicitly promoted: `ofxGgml`, `ofxGgml##`, `ofxGgml___`,
  `ofxGgml______________`, `ofxGgml_X`, `ofxGgmlAAAA`,
  `ofxGgmlDiffusion`, and `ofxGgmlXXX`.

## All-Addon Improvement Queue

Use this queue when the goal is to improve the whole managed family without
editing addon runtime behavior.

| Stage | Target | Action | Stop condition |
| --- | --- | --- | --- |
| 1 | `ofxGgmlCore` | Run planning/readiness commands and publish the current queue. | Core validation or planning failure. |
| 2 | `ofxGgmlWorkflows` | Land reusable policy, fixtures, manifest checks, and caller examples. | Local workflow validation failure. |
| 3 | `ofxGgmlSam` | Keep the SAM3 CPU evidence pilot advisory while repeated clean runs are reviewed. | Missing evidence producer or dirty target repo. |
| 4 | Clean companion repos | Add advisory workflow callers only after the Sam pilot is stable. | Missing caller scripts or stale Core plan. |
| 5 | Dirty managed repos | Review unrelated work before rollout: StableDiffusion and Rag. | Any unresolved dirty tree. |
| 6 | Accelerator lanes | Add CUDA, Metal, or Vulkan certification only for repos with real self-hosted runner evidence. | No runner, no executable smoke, or stale evidence. |

The queue is intentionally conservative: improve shared policy first, prove one
CPU lane, then fan out advisory callers to clean companions before requiring
evidence or release gates.

## Recommended Pilot

Pilot `ofxGgmlSam` CPU smoke-build evidence first.

Reasons:

- `ofxGgmlSam` is a clean managed companion and already owns the first evidence
  wrapper and advisory promotion path.
- CPU smoke avoids self-hosted CUDA, Metal, or Vulkan runner complexity.
- `ofxGgmlSamPointExample` provides a concrete openFrameworks target.
- The ownership split stays clean: Core selects and interprets the lane,
  Workflows validates and uploads evidence, and the companion emits JSON.

## Rollout Phases

1. Use Core planning to select the pilot target and expected artifact paths.
2. Add advisory Evidence Schema v1 JSON generation in the companion.
3. Follow `docs\sam-evidence-pilot-handoff.md` for the Sam pilot evidence
   wrapper before enabling the caller.
4. Enable `evidence-validation.yml` in advisory mode for the pilot path.
5. Promote `of-smoke-build.yml` required script and evidence inputs only after
   the pilot generator is stable.
6. Let Core ingest the pilot evidence for dashboard and registry visibility.
7. Add CPU `backend-runtime-check.yml` evidence after platform-native scripts
   are stable.
8. Run `release-gate.yml` in advisory mode with evidence quality reporting.
9. Promote current-SHA, schema-valid, freshness, and certification filters only
   after repeated clean pilot runs.

## Future Feature Ideas

- Generate an adoption matrix that shows each managed addon's workflow
  coverage, advisory or required gate state, evidence artifacts, and next
  recommended promotion.
- Keep workflow fixture tests for advisory versus required modes aligned with
  the manifest-owned fixture pairs.
- Promote optional evidence provenance, dirty-tree disclosure, and artifact
  integrity hints into stricter gates only after advisory pilot evidence is
  stable.
- Keep validator/schema consistency checks so Evidence Schema v1 and
  `scripts/validate-evidence.py` do not drift.
- Keep policy profiles such as `advisory`, `schema`, `current-sha`,
  `fresh-current-sha`, `reports`, `evidence`, and `release` manifest-owned to
  reduce caller YAML complexity while preserving explicit inputs.
- Maintain a runner capability registry for self-hosted accelerator lanes.
- Add a release train simulator in Core that combines readiness, metadata,
  evidence freshness, and capability reports into a dry-run decision.

## Guardrails

- Keep reusable policy in `ofxGgmlWorkflows`.
- Keep aggregation, dashboards, freshness interpretation, and release-train
  planning in `ofxGgmlCore`.
- Keep backend/model-specific commands and evidence producers in companion
  addons.
- Avoid broad enforcement while target repositories have unrelated dirty
  changes.
- Defer accelerator certification expansion until CPU smoke evidence is stable.
