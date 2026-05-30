param()

$ErrorActionPreference = "Stop"

function Assert-NoBom {
	param(
		[string]$Path,
		[string]$Label
	)
	$bytes = [System.IO.File]::ReadAllBytes($Path)
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
		throw "$Label contains a UTF-8 BOM which can break YAML parsing and shell execution"
	}
}

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Assert-Path {
	param(
		[string]$Path,
		[string]$Label,
		[switch]$Directory
	)

	if ($Directory) {
		if (!(Test-Path -LiteralPath $Path -PathType Container)) {
			throw "$Label was not found: $Path"
		}
	} elseif (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
		throw "$Label was not found: $Path"
	}
}

function Assert-FileContains {
	param(
		[string]$Path,
		[string]$Pattern,
		[string]$Label
	)

	$content = Get-Content -LiteralPath $Path -Raw
	if ($content -notmatch $Pattern) {
		throw "$Label did not contain expected pattern: $Pattern"
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$workflowRoot = Join-Path $repoRoot ".github\workflows"

Write-Step "Checking workflow repository structure"
Assert-Path (Join-Path $repoRoot "README.md") "README"
Assert-Path (Join-Path $repoRoot "CHANGELOG.md") "CHANGELOG"
Assert-Path (Join-Path $repoRoot ".gitignore") ".gitignore"
Assert-Path (Join-Path $repoRoot "docs\workflow-adoption.md") "workflow adoption docs"
Assert-Path (Join-Path $repoRoot "docs\codex-qwen3-rtx3090-profile.md") "Codex Qwen RTX 3090 profile"
Assert-Path (Join-Path $repoRoot "docs\codex-ecosystem-usage.md") "ecosystem usage docs"
Assert-Path (Join-Path $repoRoot "scripts\workflow-metadata-extractor.ps1") "workflow metadata extractor"
Assert-Path (Join-Path $repoRoot "HERMES.md") "Hermes instructions"
Assert-Path (Join-Path $repoRoot "AGENTS.md") "Codex instructions"
Assert-Path (Join-Path $repoRoot ".github\copilot-instructions.md") "Copilot instructions"
Assert-Path (Join-Path $repoRoot ".github\instructions\ofxggml-ecosystem.instructions.md") "Copilot ecosystem instructions"
Assert-Path $workflowRoot "workflow directory" -Directory

Write-Step "Checking for UTF-8 BOM"
Assert-NoBom (Join-Path $repoRoot "README.md") "README"
Assert-NoBom (Join-Path $repoRoot "CHANGELOG.md") "CHANGELOG"
Assert-NoBom (Join-Path $repoRoot ".gitignore") ".gitignore"
Assert-NoBom (Join-Path $repoRoot "scripts\validate-local.ps1") "validate-local.ps1"
Assert-NoBom (Join-Path $repoRoot ".github\copilot-instructions.md") "copilot-instructions.md"
Assert-NoBom (Join-Path $repoRoot "docs\codex-ecosystem-usage.md") "ecosystem usage docs"
Assert-NoBom (Join-Path $repoRoot "scripts\workflow-metadata-extractor.ps1") "workflow metadata extractor"

$workflowFiles = @(Get-ChildItem -LiteralPath $workflowRoot -Filter "*.yml" -File)
foreach ($workflow in $workflowFiles) {
	Assert-NoBom $workflow.FullName $workflow.Name
}

Write-Step "Checking documented workflow coverage"
Assert-FileContains (Join-Path $repoRoot "README.md") "addon-hygiene.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "coding-agent-instructions.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "ofxggml-ecosystem.instructions.md" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "release-check.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "workflow-repo-validation.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "workflow-adoption.md" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "codex-qwen3-rtx3090-profile.md" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "backend-runtime-check.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "cuda-runtime-certification.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "ecosystem-health.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "release-gate.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "metadata-validation.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "workflow_call" "README"
Assert-FileContains (Join-Path $repoRoot "docs\codex-qwen3-rtx3090-profile.md") "Qwen3.6-27B-Q4_0" "Codex Qwen RTX 3090 profile"
Assert-FileContains (Join-Path $repoRoot "docs\codex-qwen3-rtx3090-profile.md") "RTX 3090" "Codex Qwen RTX 3090 profile"
Assert-FileContains (Join-Path $repoRoot "docs\codex-qwen3-rtx3090-profile.md") "self-planning" "Codex Qwen RTX 3090 profile"
Assert-FileContains (Join-Path $repoRoot "docs\codex-qwen3-rtx3090-profile.md") "memory" "Codex Qwen RTX 3090 profile"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "coding-agent-instructions.yml" "workflow adoption docs"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "check-ecosystem-readiness.bat" "workflow adoption docs"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "workflow_call" "workflow adoption docs"

Write-Step "Checking workflow optional inputs"
Assert-FileContains (Join-Path $workflowRoot "addon-hygiene.yml") "require_addon_config" "addon-hygiene.yml"
Assert-FileContains (Join-Path $workflowRoot "addon-hygiene.yml") "require_src" "addon-hygiene.yml"
Assert-FileContains (Join-Path $workflowRoot "addon-hygiene.yml") "require_examples" "addon-hygiene.yml"
Assert-FileContains (Join-Path $workflowRoot "release-check.yml") "require_addon_config" "release-check.yml"
Assert-FileContains (Join-Path $workflowRoot "metadata-validation.yml") "require_feature_metadata" "metadata-validation.yml"
Assert-FileContains (Join-Path $workflowRoot "metadata-validation.yml") "require_readme_features" "metadata-validation.yml"
Assert-FileContains (Join-Path $repoRoot "README.md") "require_addon_config" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "require_src" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "require_examples" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "require_feature_metadata" "README"
Assert-FileContains (Join-Path $repoRoot "CHANGELOG.md") "require_addon_config" "CHANGELOG"

Write-Step "Checking workflow metadata extractor"
$metadataJson = & (Join-Path $repoRoot "scripts\workflow-metadata-extractor.ps1") -WorkflowPath (Join-Path $workflowRoot "addon-hygiene.yml")
$metadata = $metadataJson | ConvertFrom-Json
if ($metadata.workflow_name -ne "reusable-addon-hygiene") {
	throw "workflow metadata extractor returned the wrong workflow name."
}
if ($metadata.input_count -lt 3) {
	throw "workflow metadata extractor did not detect addon-hygiene inputs."
}

Write-Step "Checking coding-agent instruction guidance"
Assert-FileContains (Join-Path $repoRoot "HERMES.md") "ofxGgmlWorkflows" "Hermes instructions"
Assert-FileContains (Join-Path $repoRoot "HERMES.md") "workflow_call" "Hermes instructions"
Assert-FileContains (Join-Path $repoRoot "AGENTS.md") "ofxGgmlWorkflows" "Codex instructions"
Assert-FileContains (Join-Path $repoRoot "AGENTS.md") "workflow_call" "Codex instructions"
Assert-FileContains (Join-Path $repoRoot ".github\copilot-instructions.md") "ofxGgmlWorkflows" "Copilot instructions"
Assert-FileContains (Join-Path $repoRoot ".github\copilot-instructions.md") "workflow_call" "Copilot instructions"
Assert-FileContains (Join-Path $repoRoot ".github\instructions\ofxggml-ecosystem.instructions.md") "ofxGgmlWorkflows" "Copilot ecosystem instructions"
Assert-FileContains (Join-Path $repoRoot ".github\instructions\ofxggml-ecosystem.instructions.md") "check-ecosystem-readiness" "Copilot ecosystem instructions"

Write-Step "Checking workflow files"
if ($workflowFiles.Count -eq 0) {
	throw "No workflow files found."
}

foreach ($workflow in $workflowFiles) {
	$content = Get-Content -LiteralPath $workflow.FullName -Raw
	if ($content -notmatch "(?m)^name:\s*\S+") {
		throw "$($workflow.Name) is missing a workflow name."
	}
	if ($content -notmatch "(?m)^jobs:") {
		throw "$($workflow.Name) is missing jobs."
	}
	if ($content -match "`t") {
		throw "$($workflow.Name) contains tab characters."
	}
}

foreach ($requiredReusable in @(
	"addon-hygiene.yml",
	"coding-agent-instructions.yml",
	"release-check.yml"
)) {
	$path = Join-Path $workflowRoot $requiredReusable
	Assert-Path $path $requiredReusable
	Assert-FileContains $path "workflow_call" $requiredReusable
}
Assert-FileContains (Join-Path $workflowRoot "coding-agent-instructions.yml") "ofxggml-ecosystem.instructions.md" "coding-agent-instructions.yml"

$selfValidation = Join-Path $workflowRoot "workflow-repo-validation.yml"
Assert-Path $selfValidation "workflow-repo-validation.yml"
Assert-FileContains $selfValidation "scripts/validate-local.ps1" "workflow-repo-validation.yml"

Write-Step "ofxGgmlWorkflows local validation passed"
