# Agent Handoff Contract

Use this contract when an agent proposes or performs cross-repo ecosystem work,
workflow rollout, evidence promotion, release gating, or companion PR fanout.
Small single-repo documentation or validation fixes may simply mention that no
handoff is required.

The handoff is a planning artifact. It is not permission to edit companion
source, generated projects, model files, downloaded runtimes, or build output.

## Required Fields

| Field | Purpose |
| --- | --- |
| Task class | One of `documentation`, `automation`, `validation`, `workflow-rollout`, `evidence-rollout`, `release-planning`, or `addon-code`. |
| Owning lane | Primary owner: `ofxGgmlWorkflows`, `ofxGgmlCore`, or a companion addon. |
| Repositories touched | Exact repositories changed or proposed. Include `none` for planning-only work. |
| Core planning command | Core command used before cross-repo work, usually `scripts\plan-ecosystem.ps1 -Json -SummaryOnly`; include result summary. |
| Dirty-repo caveats | Managed repositories with unrelated dirty changes that should block or pause fanout. |
| Dirty-state table | Repo, files/count, relevance, owner/unknown, generated-artifact flag, and action: stop, pause fanout, or proceed read-only. |
| Delegation roles | Subagents or sibling agents used, their scopes, and whether they were read-only or had disjoint write scopes. |
| Integration owner | The single agent responsible for reconciling delegated outputs before validation. |
| Accepted outputs | Delegated findings or patches integrated into the final change. |
| Rejected/unused outputs | Delegated findings that were useful but out of scope, conflicting, or unsafe. |
| Final validation owner | Agent responsible for final validation result and handoff accuracy. |
| Workflow tier | Adoption tier from `docs\workflow-adoption.md`, or `none`. |
| Caller workflows changed | Caller workflow files added or changed, or `none`. |
| Rollout profile | `evidence_profile`, `release_profile`, advisory/required mode, or `custom` boolean inputs. |
| Evidence paths | Evidence or report artifact paths affected, or `none`. |
| Ownership boundary | What Workflows owns, what Core interprets, and what companions must generate or execute. |
| Validation commands | Commands run before handoff, with pass/fail result. |
| Stop conditions | Conditions that should halt the next agent, such as dirty repo, missing script, stale evidence, or failed validation. |
| Next action | One focused next step for the receiving agent. |

## Markdown Template

```markdown
## Agent Handoff

- Task class:
- Owning lane:
- Repositories touched:
- Core planning command:
- Core planning summary:
- Dirty-repo caveats:
- Dirty-state table:
- Delegation roles:
- Integration owner:
- Accepted outputs:
- Rejected/unused outputs:
- Final validation owner:
- Workflow tier:
- Caller workflows changed:
- Rollout profile:
- Evidence paths:
- Ownership boundary:
- Validation commands:
- Stop conditions:
- Next action:
```

## Example: Sam CPU Evidence Pilot

```markdown
## Agent Handoff

- Task class: evidence-rollout
- Owning lane: ofxGgmlSam companion, coordinated by ofxGgmlCore
- Repositories touched: ofxGgmlSam
- Core planning command: scripts\plan-ecosystem.ps1 -Json -SummaryOnly
- Core planning summary: ofxGgmlSam is present, clean, and ready; dirty repos are not part of this pilot.
- Dirty-repo caveats: pause fanout to ofxGgmlVideo, ofxGgmlStableDiffusion, and ofxGgmlRag until unrelated changes are reviewed.
- Dirty-state table: ofxGgmlSam clean/proceed; unrelated dirty repos pause fanout.
- Delegation roles: none.
- Integration owner: main agent.
- Accepted outputs: none.
- Rejected/unused outputs: none.
- Final validation owner: main agent.
- Workflow tier: Runtime certification, advisory evidence validation
- Caller workflows changed: .github/workflows/evidence-validation.yml
- Rollout profile: evidence_profile=advisory
- Evidence paths: build/of-smoke/of-smoke-build.json; build/evidence/evidence-quality.md
- Ownership boundary: Workflows validates schema and uploads artifacts; Core interprets freshness and dashboard status; ofxGgmlSam generates JSON evidence.
- Validation commands: scripts\validate-local.ps1 passed in the touched repository.
- Stop conditions: missing evidence generator, stale Core plan, dirty target repo, or failing local validation.
- Next action: Add advisory evidence generation for ofxGgmlSamPointExample without changing runtime behavior.
```

## Notes

- Keep one companion workflow adoption PR per handoff unless Core planning
  explicitly emits a fanout queue.
- Prefer advisory evidence before required gates.
- Use `custom` profiles only when the preset profiles cannot express the
  intended rollout state.
- Do not treat workflow adoption as permission to edit addon runtime behavior.
