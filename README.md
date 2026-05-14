# ofxGgmlWorkflows

Reusable GitHub Actions workflows and policy templates for the ofxGgml addon ecosystem.

This repository centralizes lightweight automation for openFrameworks addons in the `ofxGgml` family.

## Workflows

- `.github/workflows/addon-hygiene.yml`
- `.github/workflows/coding-agent-instructions.yml`
- `.github/workflows/release-check.yml`
- `.github/workflows/workflow-repo-validation.yml`

Companion repositories can consume these workflows with `workflow_call`.
See [`docs/workflow-adoption.md`](docs/workflow-adoption.md) for adoption
tiers, caller patterns, and Core coordination notes.

Example:

```yaml
name: addon-hygiene

on:
  push:
  pull_request:

jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
```

## Policy

The workflows enforce basic addon structure, artifact hygiene, and release readiness without requiring heavyweight native builds.

`coding-agent-instructions.yml` checks that consuming repositories carry
Hermes Agent `HERMES.md` project context, Codex-style `AGENTS.md` guidance, and
GitHub Copilot repository instructions plus
`.github/instructions/ofxggml-ecosystem.instructions.md` for focused Copilot
cloud agent and code review guardrails.

`workflow-repo-validation.yml` validates this repository's reusable workflow
templates on push and pull request.

## Adoption order

1. Add `coding-agent-instructions.yml` so Codex, GitHub Copilot, and Hermes
   Agent guidance stays present.
2. Add hygiene, metadata, and release checks before widening runtime behavior.
3. Add status and health workflows so `ofxGgmlCore` can observe ecosystem
   readiness.
4. Add runtime certification workflows only for lanes with relevant local
   validation.

## Validate

```powershell
scripts\validate-local.bat
```

On macOS/Linux:

```sh
./scripts/validate-local.sh
```
