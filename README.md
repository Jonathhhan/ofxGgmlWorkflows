# ofxGgmlWorkflows

Reusable GitHub Actions workflows and policy templates for the ofxGgml addon ecosystem.

This repository centralizes lightweight automation for openFrameworks addons in the `ofxGgml` family.

## Workflows

- `.github/workflows/addon-hygiene.yml`
- `.github/workflows/coding-agent-instructions.yml`
- `.github/workflows/release-check.yml`
- `.github/workflows/workflow-repo-validation.yml`

Companion repositories can consume these workflows with `workflow_call`.

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
GitHub Copilot repository instructions.

`workflow-repo-validation.yml` validates this repository's reusable workflow
templates on push and pull request.

## Validate

```powershell
scripts\validate-local.bat
```

On macOS/Linux:

```sh
./scripts/validate-local.sh
```
