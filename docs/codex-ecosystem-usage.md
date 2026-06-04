# Codex Ecosystem Usage Guide

## Overview

Codex can effectively manage the ofxGgml ecosystem by leveraging its role as a reusable workflow/template library. The key is to use Codex for **ecosystem-level coordination** while keeping addon-specific work in companion repositories.

## Core Principles

### 1. Lane-Based Approach
- **Codex (ofxGgmlWorkflows)**: Reusable workflow templates, policy checks, ecosystem automation
- **Companion Addons**: Model-specific workflows, runtime behavior, examples
- **ofxGgmlCore**: Shared base, domain-neutral primitives, planning tools

### 2. Dependency Direction

```text
Companion Addons -> ofxGgmlCore (shared primitives)
ofxGgmlCore -> Companions (no reverse dependencies)
```

### 3. Scope Discipline
- Keep changes scoped to lane responsibilities
- Cross-repo coordination requires ecosystem plans
- Model-specific UX stays in companion addons

## Codex Usage Patterns

### Pattern 1: Ecosystem Planning
**When to use:** Cross-repo improvements, planning, coordination

**How:**
```powershell
# From ofxGgmlCore
scripts\plan-ecosystem.ps1
```

**Codex's role:**
- Review ecosystem plans
- Identify workflow template needs
- Ensure consistency across companions
- Validate governance patterns
- Produce an agent handoff from `docs\agent-handoff-contract.md` before
  companion PR fanout or evidence promotion

### Pattern 2: Workflow Template Development
**When to use:** Creating reusable GitHub Actions workflows

**How:**
1. Start with HERMES.md and AGENTS.md context
2. Read existing workflows for patterns
3. Create focused, validated changes
4. Run scripts\validate-local.ps1 before committing

**Example workflow:**
```yaml
name: addon-hygiene

on:
  push:
  pull_request:

jobs:
  hygiene:
    uses: Jonathhhan/ofxGgmlWorkflows/.github/workflows/addon-hygiene.yml@main
```

### Pattern 3: Addon Coordination
**When to use:** Adding workflows to companion addons

**How:**
1. Reference docs/workflow-adoption.md for adoption tiers
2. Start with required agent baseline
3. Add hygiene checks before runtime behavior
4. Keep caller workflows small, reusable workflow owns policy

**Adoption order:**
1. coding-agent-instructions.yml
2. addon-hygiene.yml, metadata-validation.yml, release-check.yml
3. Operational visibility workflows
4. Runtime certification (lane-specific)

### Pattern 4: Governance Enforcement
**When to use:** Ensuring ecosystem consistency

**How:**
- Use coding-agent-instructions.yml to verify HERMES.md, AGENTS.md, Copilot instructions
- Run scripts\validate-local.ps1 for repository integrity
- Check workflow inheritance and compatibility

### Pattern 5: Documentation Maintenance
**When to use:** Keeping docs current and accurate

**How:**
- Update README.md when workflows change
- Document workflow parameters and usage
- Maintain docs/workflow-adoption.md for adoption guidance

## Best Practices

### 1. Start with Context
Always read HERMES.md, AGENTS.md, and `docs\agent-baseline.md` before making
changes.

### 2. Validate Before Committing
Run scripts\validate-local.ps1 to ensure repository integrity.

### 3. Keep Changes Focused
- Small, validated changes over broad refactors
- One workflow per PR when possible
- Preserve openFrameworks-style public names

### 4. Use ofxGgmlCore for Planning
For cross-repo work, use planning tools from Core:
- scripts\plan-ecosystem.ps1
- scripts\status-family.ps1
- scripts\check-ecosystem-readiness.bat

### 5. Preserve Ecosystem Split
- Model-specific workflows -> Companion addons
- Shared helpers -> ofxGgmlCore (when stable and tested)

### 6. Avoid Reverse Dependencies
- Companions may depend on Core
- Core must NOT depend on companions

### 7. Use Handoffs For Fanout
- Use `docs\agent-handoff-contract.md` before cross-repo workflow rollout,
  evidence promotion, release planning, or companion PR fanout.
- Include dirty-repo caveats and stop conditions so the receiving agent knows
  when to pause instead of widening changes.

## Common Workflows

### Adding a New Workflow
1. Review existing workflows for patterns
2. Create workflow template in .github/workflows/
3. Update README.md with workflow description
4. Update docs/workflow-adoption.md with new tier
5. Run validation
6. Create PR with example caller

### Updating Existing Workflow
1. Read current implementation
2. Identify needed changes
3. Validate with scripts\validate-local.ps1
4. Update documentation
5. Test with example callers

### Ecosystem Health Check
1. Run scripts\validate-local.ps1
2. Check workflow inheritance
3. Verify governance files present
4. Review ecosystem-health.yml output

## Tooling

### Validation
```powershell
scripts\validate-local.ps1
```

### Planning (from ofxGgmlCore)
```powershell
scripts\plan-ecosystem.ps1
scripts\status-family.ps1
scripts\check-ecosystem-readiness.bat
```

### Workflow Status
```bash
scripts\fetch-workflow-status.py
```

## Example: Using Codex for Ecosystem Improvement

**Task:** Add a new workflow for testing companion addons

**Steps:**
1. Read HERMES.md and AGENTS.md for context
2. Review existing workflow patterns
3. Create addon-test.yml workflow template
4. Update docs/workflow-adoption.md with new tier
5. Run validation
6. Create PR with example caller in a companion addon

**Codex's role:**
- Design workflow template
- Ensure consistency with existing workflows
- Validate against governance patterns
- Document usage and parameters

## Summary

Codex excels at:
- **Ecosystem coordination** via reusable workflows
- **Governance enforcement** through validation
- **Documentation** of patterns and best practices
- **Template creation** for common automation tasks

The key is to use Codex for **ecosystem-level** work and let companion addons handle **model-specific** implementation details.
