# Future Ecosystem Roadmap

This roadmap captures the current Hermes-style ecosystem review for
ofxGgmlWorkflows. It is a planning artifact, not permission to edit companion
addon source.

## Current Status

- `ofxGgmlWorkflows` is clean and owns reusable `workflow_call` contracts,
  policy checks, evidence validation, and automation docs.
- `ofxGgmlCore` remains the shared base and ecosystem planning/dashboard
  control plane.
- Companion addons own backend-specific scripts, model-specific UX, and
  evidence generation.
- Core planning currently recommends making one backend lane genuinely useful
  before broadening automation across all companions.
- Dirty managed repositories should be reviewed before fanout enforcement:
  `ofxGgmlCore`, `ofxGgmlVideo`, `ofxGgmlStableDiffusion`, and `ofxGgmlRag`.

## Recommended Pilot

Pilot `ofxGgmlSam` CPU smoke-build evidence first.

Reasons:

- `ofxGgmlSam` is a clean managed companion and already appears in the Core
  smoke-build lifecycle.
- CPU smoke avoids self-hosted CUDA, Metal, or Vulkan runner complexity.
- `ofxGgmlSamPointExample` provides a concrete openFrameworks target.
- The ownership split stays clean: Core selects and interprets the lane,
  Workflows validates and uploads evidence, and the companion emits JSON.

## Rollout Phases

1. Use Core planning to select the pilot target and expected artifact paths.
2. Add advisory Evidence Schema v1 JSON generation in the companion.
3. Enable `evidence-validation.yml` in advisory mode for the pilot path.
4. Promote `of-smoke-build.yml` required script and evidence inputs only after
   the pilot generator is stable.
5. Let Core ingest the pilot evidence for dashboard and registry visibility.
6. Add CPU `backend-runtime-check.yml` evidence after platform-native scripts
   are stable.
7. Run `release-gate.yml` in advisory mode with evidence quality reporting.
8. Promote current-SHA, schema-valid, freshness, and certification filters only
   after repeated clean pilot runs.

## Future Feature Ideas

- Generate an adoption matrix that shows each managed addon's workflow
  coverage, advisory or required gate state, evidence artifacts, and next
  recommended promotion.
- Add workflow fixture tests for advisory versus required modes.
- Promote optional evidence provenance, dirty-tree disclosure, and artifact
  integrity hints into stricter gates only after advisory pilot evidence is
  stable.
- Add validator/schema consistency checks so Evidence Schema v1 and
  `scripts/validate-evidence.py` do not drift.
- Add policy profiles such as `advisory`, `pr`, `certification`, and `release`
  to reduce caller YAML complexity while preserving explicit inputs.
- Maintain a runner capability registry for self-hosted accelerator lanes.
- Add a release train simulator in Core that combines readiness, metadata,
  evidence freshness, and capability reports into a dry-run decision.

## Guardrails

- Keep reusable policy in `ofxGgmlWorkflows`.
- Keep aggregation, dashboards, freshness interpretation, and release-train
  planning in `ofxGgmlCore`.
- Keep backend/model-specific commands and evidence producers in companion
  addons.
- Avoid broad enforcement while managed repositories have unrelated dirty
  changes.
- Defer accelerator certification expansion until CPU smoke evidence is stable.
