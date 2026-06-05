# Hermes Memory Contract

Hermes can use permanent memory for ecosystem work, but memory is never more
authoritative than the current repository files. Treat memory as a durable
retrieval index that points back to local source documents, not as hidden model
state or a replacement for reading instructions.

## Contract

A Hermes memory index must:

- Use `schema_version` 1 from `schemas/hermes-memory-v1.schema.json`.
- Store the repository name, current `commit_sha`, `tree_state`, and
  `generated_at` timestamp.
- Store one record per source-grounded fact packet.
- Include `source_path`, `source_sha256`, `source_modified_at`, `repo`, `lane`,
  `source_type`, `freshness`, `summary`, and `retrieval_tags` for every record.
- Prefer current source files when the index commit or freshness is stale.
- Stay generated. Do not commit memory indexes, vector stores, embedding
  caches, model weights, downloaded runtimes, or sample media dumps.

The default generated output is:

```powershell
scripts\write-hermes-memory-index.ps1 -OutputPath build\hermes-memory\hermes-memory-index.json
```

Check a generated index before relying on it:

```powershell
scripts\check-hermes-memory-index.ps1 -IndexPath build\hermes-memory\hermes-memory-index.json -Json
```

## Source Types

Use `instruction` for agent rules, `workflow` for reusable workflow contracts,
`runtime` for ggml/Core provider facts, `evidence` for release and runtime
evidence policy, `validation` for tests and local gates, `planning` for
ecosystem rollout and handoff rules, `release` for release policy, `security`
for hardening and provenance, `example` for openFrameworks examples, and
`memory` for memory contract material.

## Refresh Rules

Regenerate the index before Hermes starts a cross-repo task, release-facing
task, or agent-improvement task. If `tree_state` is `dirty`, Hermes may still
use the index for orientation, but it must also read the touched files directly
and report dirty-repo caveats in the handoff.

Stop and refresh memory when:

- The index `commit_sha` does not match the current checkout.
- A retrieved `source_path` no longer exists.
- A retrieved file's current SHA-256 digest no longer matches the record's
  `source_sha256`.
- A retrieved file was modified after the record's `source_modified_at`.
- A task depends on release evidence, workflow policy, or runtime ownership and
  the index was generated before those files changed.
- Memory disagrees with `AGENTS.md`, `HERMES.md`, or the current lane docs.

## Validation

`scripts\test-hermes-memory-index.ps1` generates a temporary index, checks the
schema title, verifies required record fields, confirms record IDs are unique,
ensures every `source_path` exists, and checks each `source_sha256` against the
current file content. `scripts\test-hermes-memory-readiness.ps1` checks the
readiness reporter against fresh, stale, changed-source, and missing indexes.
`scripts\validate-local.ps1` runs those tests before the Hermes eval catalog so
permanent-memory drift is visible early.
