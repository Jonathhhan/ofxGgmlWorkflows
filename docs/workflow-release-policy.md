# Workflow Release Policy

This repository publishes reusable GitHub Actions workflows for the ofxGgml
ecosystem. Consumers should have stable refs once a workflow contract is ready,
while `main` stays useful for pilots and fast iteration.

## Ref Types

| Ref | Purpose | Consumer guidance |
| --- | --- | --- |
| `main` | Active development and pilot adoption. | Use only for early rollout, local experiments, or managed addons that intentionally follow Workflows head. |
| `v1` | Moving major-version compatibility ref. | Preferred default for stable companion addons after the first v1 release is tagged. |
| `v1.x` | Moving minor-version compatibility ref. | Use when a companion wants a smaller rollout window than `v1`. |
| `v1.x.y` | Immutable patch release tag. | Use for release candidates, audits, or strict reproducibility. |
| Full commit SHA | Exact source pin. | Use when a caller needs maximum supply-chain control and owns update review. |

## Release Checklist

Before tagging a versioned workflow release:

1. Run `scripts\validate-local.ps1`.
2. Review `workflow-security-advice.yml` output for missing job permissions and
   non-SHA external action refs.
3. Confirm Dependabot GitHub Actions coverage is active for this repository.
4. Preserve `workflow_call` inputs unless the release is intentionally
   breaking and documented.
5. Update `CHANGELOG.md` with the workflows, scripts, and policy changes in the
   release.
6. Tag the immutable patch release, such as `v1.0.0`.
7. Move the compatible `v1` and `v1.0` refs only after validation passes on the
   release commit.

## Consumer Promotion

Keep companion callers on `@main` while a workflow is advisory or still changing
weekly. Promote to `@v1` after the workflow has a stable input contract, local
validation coverage, and at least one clean run in the consuming addon. Promote
release-facing callers to an immutable `v1.x.y` tag when reproducibility matters
more than automatic workflow updates.

## Dependabot Role

`.github/dependabot.yml` keeps GitHub Actions dependencies visible as reviewed
pull requests. This is the staging step before strict SHA pinning: first make
updates reviewable, then use `workflow-security-advice.yml` to decide which
external actions should move from tag refs to full commit SHAs.
