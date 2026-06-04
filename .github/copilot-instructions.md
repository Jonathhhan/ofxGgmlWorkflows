# GitHub Copilot Repository Instructions

ofxGgmlWorkflows is part of the ofxGgml openFrameworks addon ecosystem.

- Scope: GitHub Actions workflow_call templates, policy checks, and ecosystem automation docs
- Mirror the shared guidance in docs\agent-baseline.md.
- Keep changes inside this addon's lane unless a task explicitly asks for a cross-addon update.
- For ecosystem planning tasks, prefer instruction, documentation, workflow, and validation changes before addon source changes.
- Use ofxGgmlCore as the default shared ggml/runtime base for companion addons and keep companion workflows out of Core.
- Avoid committing generated outputs, local models, build directories, IDE metadata, downloaded runtimes, caches, or media dumps.
- Use openFrameworks ofLogNotice, ofLogWarning, ofLogError, or module-scoped ofLog(...) for addon runtime/example logging; keep raw stdout/stderr only for tests and CLI tools with machine-readable output contracts.
- Add or update headless tests for public helper behavior.
- For cross-repo workflow rollout, evidence promotion, release planning, or companion PR fanout, use docs\agent-handoff-contract.md.
- Validation before handoff: scripts\validate-local.ps1.
- Keep explanations concise and include the files and checks that matter.
