$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$plannerPath = Join-Path $repoRoot "scripts\plan-hermes-source-learning.ps1"

if (!(Test-Path -LiteralPath $plannerPath -PathType Leaf)) {
	throw "Hermes source-learning planner was not found: $plannerPath"
}

$plan = (& $plannerPath -Json) | ConvertFrom-Json
if ([int]$plan.schema_version -ne 1) {
	throw "Hermes source-learning plan schema_version must be 1."
}
if ([string]$plan.requested_lane -ne "all") {
	throw "Hermes source-learning default lane should be all."
}

$sources = @($plan.sources)
if ($sources.Count -ne 5) {
	throw "Hermes source-learning plan should include 5 upstream sources."
}

$sourceIds = @($sources | Select-Object -ExpandProperty id)
foreach ($requiredId in @("openframeworks", "ggml", "llama-cpp", "whisper-cpp", "stable-diffusion-cpp")) {
	if ($requiredId -notin $sourceIds) {
		throw "Hermes source-learning plan is missing source: $requiredId"
	}
}

foreach ($path in @("AGENTS.md", "HERMES.md", "docs/hermes-source-learning-map.md", "docs/hermes-openframeworks-ggml-skills.md")) {
	if ($path -notin @($plan.local_first)) {
		throw "Hermes source-learning plan local_first is missing: $path"
	}
}

$openFrameworks = @($sources | Where-Object { $_.id -eq "openframeworks" })[0]
foreach ($folder in @("addons", "apps", "docs", "examples", "libs", "scripts", "projectGenerator")) {
	if ($folder -notin @($openFrameworks.read_first)) {
		throw "openFrameworks source-learning plan is missing folder: $folder"
	}
}
if (@($openFrameworks.learn | Where-Object { $_ -match "self-contained" }).Count -eq 0) {
	throw "openFrameworks source-learning plan must mention self-contained releases."
}

$diffusion = @($sources | Where-Object { $_.id -eq "stable-diffusion-cpp" })[0]
foreach ($token in @("backend selection", "quantization and GGUF docs", "CLI docs")) {
	if ($token -notin @($diffusion.read_first)) {
		throw "stable-diffusion.cpp source-learning plan is missing: $token"
	}
}

$addonPlan = (& $plannerPath -Lane addon-layout -Json) | ConvertFrom-Json
if (@($addonPlan.sources).Count -ne 1 -or [string]$addonPlan.sources[0].id -ne "openframeworks") {
	throw "addon-layout lane should select only openFrameworks."
}

foreach ($condition in @($plan.stop_conditions)) {
	if ([string]::IsNullOrWhiteSpace([string]$condition)) {
		throw "Hermes source-learning stop conditions must be non-empty."
	}
}

Write-Host "Hermes source-learning plan checks passed."
