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

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$workflowRoot = Join-Path $repoRoot ".github\workflows"

Write-Step "Checking manifest-backed repository inventory"
Assert-Path (Join-Path $repoRoot "schemas\validation-manifest.json") "validation manifest"
Assert-Path (Join-Path $repoRoot "scripts\test-validation-manifest.ps1") "validation manifest tests"
Assert-Path $workflowRoot "workflow directory" -Directory
& (Join-Path $repoRoot "scripts\test-validation-manifest.ps1")

Write-Step "Checking workflow file syntax"
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

Write-Step "Checking evidence schema JSON"
$schemaJson = Get-Content -LiteralPath (Join-Path $repoRoot "schemas\evidence-v1.schema.json") -Raw | ConvertFrom-Json
if ($schemaJson.title -ne "ofxGgml Evidence v1") {
	throw "evidence schema returned the wrong title."
}

& (Join-Path $repoRoot "scripts\test-evidence-schema-drift.ps1")
& (Join-Path $repoRoot "scripts\test-evidence-validator.ps1")
& (Join-Path $repoRoot "scripts\test-evidence-promotion-advisor.ps1")
& (Join-Path $repoRoot "scripts\test-workflow-profiles.ps1")
& (Join-Path $repoRoot "scripts\test-workflow-fixtures.ps1")
& (Join-Path $repoRoot "scripts\test-workflow-security-advice.ps1")

Write-Step "Checking Hermes eval catalog"
& (Join-Path $repoRoot "scripts\test-hermes-eval-catalog.ps1")

Write-Step "Checking workflow metadata extractor"
$metadataJson = & (Join-Path $repoRoot "scripts\workflow-metadata-extractor.ps1") -WorkflowPath (Join-Path $workflowRoot "addon-hygiene.yml")
$metadata = $metadataJson | ConvertFrom-Json
if ($metadata.workflow_name -ne "reusable-addon-hygiene") {
	throw "workflow metadata extractor returned the wrong workflow name."
}
if ($metadata.input_count -lt 3) {
	throw "workflow metadata extractor did not detect addon-hygiene inputs."
}

Write-Step "ofxGgmlWorkflows local validation passed"
