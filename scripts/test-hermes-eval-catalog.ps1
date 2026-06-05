$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$catalogPath = Join-Path $repoRoot "docs\hermes-openframeworks-ggml-evals.json"
$markdownPath = Join-Path $repoRoot "docs\hermes-openframeworks-ggml-evals.md"

if (!(Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
	throw "Hermes eval catalog was not found: $catalogPath"
}
if (!(Test-Path -LiteralPath $markdownPath -PathType Leaf)) {
	throw "Hermes eval markdown guide was not found: $markdownPath"
}

$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
if ([int]$catalog.schema_version -ne 1) {
	throw "Hermes eval catalog schema_version must be 1."
}
if ([double]$catalog.minimum_average_score -lt 0 -or [double]$catalog.minimum_average_score -gt 3) {
	throw "Hermes eval catalog minimum_average_score must fit the 0-3 score range."
}
if ([int]$catalog.minimum_safety_failures -ne 0) {
	throw "Hermes eval catalog should require zero unsafe lane-boundary failures."
}
if (@($catalog.score_scale).Count -ne 4) {
	throw "Hermes eval catalog must define four score-scale entries."
}

$scenarios = @($catalog.scenarios)
if ($scenarios.Count -lt 14) {
	throw "Hermes eval catalog should contain at least 14 scenarios."
}

$ids = @{}
foreach ($scenario in $scenarios) {
	$id = [string]$scenario.id
	if ([string]::IsNullOrWhiteSpace($id)) {
		throw "Hermes eval scenario is missing an id."
	}
	if ($ids.ContainsKey($id)) {
		throw "Hermes eval scenario id is duplicated: $id"
	}
	$ids[$id] = $true

	foreach ($property in @("title", "prompt")) {
		if ([string]::IsNullOrWhiteSpace([string]$scenario.$property)) {
			throw "Hermes eval scenario $id is missing $property."
		}
	}
	if (@($scenario.expected_behaviors).Count -eq 0) {
		throw "Hermes eval scenario $id is missing expected behaviors."
	}
	if (@($scenario.unsafe_failures).Count -eq 0) {
		throw "Hermes eval scenario $id is missing unsafe failure examples."
	}
	if ($scenario.PSObject.Properties.Name -contains "tags") {
		if (@($scenario.tags).Count -eq 0) {
			throw "Hermes eval scenario $id has an empty tags array."
		}
	}
	if (@($scenario.tags) -contains "agent_improvement") {
		foreach ($property in @("agent_roles", "measurement_signal", "required_validations", "anti_gaming_failures")) {
			if (!($scenario.PSObject.Properties.Name -contains $property) -or @($scenario.$property).Count -eq 0) {
				throw "Hermes agent-improvement scenario $id is missing $property."
			}
		}
	}
}

$allTags = @($scenarios | ForEach-Object { @($_.tags) })
foreach ($requiredTag in @("agent_improvement", "multi_agent")) {
	if ($requiredTag -notin $allTags) {
		throw "Hermes eval catalog is missing required tag: $requiredTag"
	}
}

$markdown = Get-Content -LiteralPath $markdownPath -Raw
foreach ($scenario in $scenarios) {
	if ($markdown -notmatch [regex]::Escape([string]$scenario.id)) {
		throw "Hermes eval markdown guide does not mention scenario id: $($scenario.id)"
	}
	if ($markdown -notmatch [regex]::Escape([string]$scenario.title)) {
		throw "Hermes eval markdown guide does not mention scenario title: $($scenario.title)"
	}
}

Write-Host "Hermes eval catalog checks passed ($($scenarios.Count) scenarios)."
