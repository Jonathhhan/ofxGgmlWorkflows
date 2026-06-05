param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$reportDir = Join-Path $env:TEMP ("ofxggml-workflow-security-" + [System.Guid]::NewGuid().ToString("N"))
$reportPath = Join-Path $reportDir "workflow-security-advice.md"
$jsonPath = Join-Path $reportDir "workflow-security-advice.json"

Write-Step "Checking workflow security advice report"

& (Join-Path $repoRoot "scripts\write-workflow-security-advice.ps1") `
	-WorkflowRoot (Join-Path $repoRoot ".github\workflows") `
	-ReportPath $reportPath `
	-JsonPath $jsonPath `
	-RecommendedConsumerRef "v1"

if (!(Test-Path -LiteralPath $reportPath -PathType Leaf)) {
	throw "Workflow security advice report was not written."
}
if (!(Test-Path -LiteralPath $jsonPath -PathType Leaf)) {
	throw "Workflow security advice JSON was not written."
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($pattern in @(
	"Workflow Security Advice",
	"Jobs missing explicit permissions",
	"External actions not pinned to full SHA",
	'Recommended stable consumer ref: `v1`'
)) {
	if ($report -notmatch [regex]::Escape($pattern)) {
		throw "Workflow security advice report is missing expected text: $pattern"
	}
}

$json = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ([int]$json.workflow_count -le 0) {
	throw "Workflow security advice JSON did not count workflow files."
}
if ([int]$json.missing_permissions_count -ne 0) {
	throw "Workflow security advice JSON should report zero missing job permissions after least-privilege rollout."
}
if ([int]$json.unpinned_action_count -le 0) {
	throw "Workflow security advice JSON should report non-SHA action refs during advisory rollout."
}

Write-Step "Workflow security advice checks passed"
