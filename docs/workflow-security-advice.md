# Workflow Security Advice

Advisory guidance and optional enforcement for reusable workflow hardening. Use it before making SHA pinning or least-privilege permissions required.

## Summary

| Metric | Count |
| --- | ---: |
| Workflow files | 27 |
| Jobs | 27 |
| Jobs missing explicit permissions | 0 |
| External actions not pinned to full SHA | 55 |

Recommended stable consumer ref: `v1`.

Enforcement: explicit permissions = `False`; full-SHA action refs = `False`.

## Missing Job Permissions

All jobs declare explicit permissions.

## Non-SHA Action References

| Workflow | Uses | Ref |
| --- | --- | --- |
| `$addon-hygiene.yml` | `$actions/checkout@v4` | `$v4` |
| `$backend-capability-report.yml` | `$actions/checkout@v4` | `$v4` |
| `$backend-capability-report.yml` | `$actions/setup-python@v5` | `$v5` |
| `$backend-runtime-check.yml` | `$actions/checkout@v4` | `$v4` |
| `$backend-runtime-check.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$baseline-compatibility.yml` | `$actions/checkout@v4` | `$v4` |
| `$baseline-compatibility.yml` | `$actions/setup-python@v5` | `$v5` |
| `$coding-agent-instructions.yml` | `$actions/checkout@v4` | `$v4` |
| `$compatibility-matrix.yml` | `$actions/checkout@v4` | `$v4` |
| `$compatibility-matrix.yml` | `$actions/setup-python@v5` | `$v5` |
| `$cross-repo-capability-map.yml` | `$actions/checkout@v4` | `$v4` |
| `$cross-repo-capability-map.yml` | `$actions/setup-python@v5` | `$v5` |
| `$cuda-runtime-certification.yml` | `$actions/checkout@v4` | `$v4` |
| `$cuda-runtime-certification.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$ecosystem-docs.yml` | `$actions/checkout@v4` | `$v4` |
| `$ecosystem-docs.yml` | `$actions/setup-python@v5` | `$v5` |
| `$ecosystem-health.yml` | `$actions/checkout@v4` | `$v4` |
| `$ecosystem-health-report.yml` | `$actions/checkout@v4` | `$v4` |
| `$ecosystem-health-report.yml` | `$actions/setup-python@v5` | `$v5` |
| `$evidence-promotion-advisor.yml` | `$actions/checkout@v4` | `$v4` |
| `$evidence-promotion-advisor.yml` | `$actions/checkout@v4` | `$v4` |
| `$evidence-promotion-advisor.yml` | `$actions/setup-python@v5` | `$v5` |
| `$evidence-promotion-advisor.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$evidence-validation.yml` | `$actions/checkout@v4` | `$v4` |
| `$evidence-validation.yml` | `$actions/checkout@v4` | `$v4` |
| `$evidence-validation.yml` | `$actions/setup-python@v5` | `$v5` |
| `$evidence-validation.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$live-workflow-status.yml` | `$actions/checkout@v4` | `$v4` |
| `$live-workflow-status.yml` | `$actions/setup-python@v5` | `$v5` |
| `$metadata-reconciliation.yml` | `$actions/checkout@v4` | `$v4` |
| `$metadata-reconciliation.yml` | `$actions/setup-python@v5` | `$v5` |
| `$metadata-validation.yml` | `$actions/checkout@v4` | `$v4` |
| `$metadata-validation.yml` | `$actions/setup-python@v5` | `$v5` |
| `$metal-runtime-certification.yml` | `$actions/checkout@v4` | `$v4` |
| `$metal-runtime-certification.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$multi-platform-smoke.yml` | `$actions/checkout@v4` | `$v4` |
| `$multi-platform-smoke.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$of-smoke-build.yml` | `$actions/checkout@v4` | `$v4` |
| `$of-smoke-build.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$release-check.yml` | `$actions/checkout@v4` | `$v4` |
| `$release-gate.yml` | `$actions/checkout@v4` | `$v4` |
| `$release-gate.yml` | `$actions/checkout@v4` | `$v4` |
| `$release-gate.yml` | `$actions/setup-python@v5` | `$v5` |
| `$release-plan.yml` | `$actions/checkout@v4` | `$v4` |
| `$release-plan.yml` | `$actions/setup-python@v5` | `$v5` |
| `$release-readiness-score.yml` | `$actions/checkout@v4` | `$v4` |
| `$release-readiness-score.yml` | `$actions/setup-python@v5` | `$v5` |
| `$vulkan-runtime-certification.yml` | `$actions/checkout@v4` | `$v4` |
| `$vulkan-runtime-certification.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$workflow-repo-validation.yml` | `$actions/checkout@v4` | `$v4` |
| `$workflow-security-advice.yml` | `$actions/checkout@v4` | `$v4` |
| `$workflow-security-advice.yml` | `$actions/checkout@v4` | `$v4` |
| `$workflow-security-advice.yml` | `$actions/upload-artifact@v4` | `$v4` |
| `$workflow-status-plan.yml` | `$actions/checkout@v4` | `$v4` |
| `$workflow-status-plan.yml` | `$actions/setup-python@v5` | `$v5` |

## Rollout Notes

- Start by adding explicit permissions: contents: read to read-only jobs.
- Keep tag-based external action refs visible while Dependabot coverage is added.
- Promote callers from @main to $RecommendedConsumerRef after a versioned workflow release is tagged.
