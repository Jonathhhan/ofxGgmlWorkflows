# Changelog

All notable changes to ofxGgmlWorkflows are documented here.

## Unreleased

### Added

- `addon-hygiene.yml` now accepts `require_addon_config` and `require_src` inputs for non-addon repositories
- `addon-hygiene.yml` now accepts `require_examples` for companion addons that release-maintain examples
- `metadata-validation.yml` now accepts built-in metadata and README feature checks for managed addon feature promises
- `release-check.yml` now accepts `require_addon_config` input for non-addon repositories
- Rewrote `scripts/workflow-metadata-extractor.ps1` with proper PowerShell syntax and YAML-aware metadata extraction
- Added `docs/codex-ecosystem-usage.md` with Codex ecosystem usage patterns and best practices
- `.gitignore` to prevent accidental commits of generated artifacts, model weights, build output, and IDE metadata
- Expanded README with full workflow catalog organized by adoption tier
- `CHANGELOG.md` to satisfy `release-check.yml` requirements

### Changed

- README now lists all 24 workflows grouped by adoption tier (agent baseline, addon hygiene, operational visibility, compatibility/release planning, runtime certification, self-validation)
- Local validation now checks every workflow file for UTF-8 BOMs
