param()

$ErrorActionPreference = "Stop"

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
Assert-Path (Join-Path $repoRoot "docs\workflow-adoption.md") "workflow adoption docs"
Assert-Path (Join-Path $repoRoot "HERMES.md") "Hermes instructions"
Assert-Path (Join-Path $repoRoot "AGENTS.md") "Codex instructions"
Assert-Path (Join-Path $repoRoot ".github\copilot-instructions.md") "Copilot instructions"
Assert-Path (Join-Path $repoRoot ".github\instructions\ofxggml-ecosystem.instructions.md") "Copilot ecosystem instructions"
Assert-Path $workflowRoot "workflow directory" -Directory

Write-Step "Checking documented workflow coverage"
Assert-FileContains (Join-Path $repoRoot "README.md") "addon-hygiene.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "coding-agent-instructions.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "ofxggml-ecosystem.instructions.md" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "release-check.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "workflow-repo-validation.yml" "README"
Assert-FileContains (Join-Path $repoRoot "README.md") "workflow-adoption.md" "README"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "coding-agent-instructions.yml" "workflow adoption docs"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "check-ecosystem-readiness.bat" "workflow adoption docs"
Assert-FileContains (Join-Path $repoRoot "docs\workflow-adoption.md") "workflow_call" "workflow adoption docs"

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
$workflowFiles = @(Get-ChildItem -LiteralPath $workflowRoot -Filter "*.yml" -File)
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
