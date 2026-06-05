$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$writerPath = Join-Path $repoRoot "scripts\write-hermes-memory-index.ps1"
$checkerPath = Join-Path $repoRoot "scripts\check-hermes-memory-index.ps1"

if (!(Test-Path -LiteralPath $writerPath -PathType Leaf)) {
	throw "Hermes memory writer was not found: $writerPath"
}
if (!(Test-Path -LiteralPath $checkerPath -PathType Leaf)) {
	throw "Hermes memory readiness checker was not found: $checkerPath"
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ofxggml-hermes-memory-readiness-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$indexPath = Join-Path $tempRoot "hermes-memory-index.json"
$stalePath = Join-Path $tempRoot "stale-memory-index.json"

try {
	& $writerPath -OutputPath $indexPath | Out-Null
	$readyReport = (& $checkerPath -IndexPath $indexPath -MaxAgeHours 24 -Json) | ConvertFrom-Json
	if ([string]$readyReport.status -notin @("ready", "caution")) {
		throw "Fresh Hermes memory index should be ready or caution, got: $($readyReport.status)"
	}
	if ([bool]$readyReport.ready -ne $true) {
		throw "Fresh Hermes memory index should be ready."
	}
	if ([int]$readyReport.record_count -lt 12) {
		throw "Fresh Hermes memory index returned too few records."
	}

	$index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
	$index.generated_at = [DateTimeOffset]::UtcNow.AddHours(-48).ToString("o")
	$index | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $stalePath -Encoding UTF8

	$staleReport = (& $checkerPath -IndexPath $stalePath -MaxAgeHours 1 -Json) | ConvertFrom-Json
	if ([string]$staleReport.status -ne "refresh_required") {
		throw "Stale Hermes memory index should require refresh, got: $($staleReport.status)"
	}
	if ([bool]$staleReport.ready -ne $false) {
		throw "Stale Hermes memory index should not be ready."
	}
	if (@($staleReport.issues | Where-Object { $_ -match "stale" }).Count -eq 0) {
		throw "Stale Hermes memory index report should include a stale issue."
	}

	$missingReport = (& $checkerPath -IndexPath (Join-Path $tempRoot "missing.json") -Json) | ConvertFrom-Json
	if ([string]$missingReport.status -ne "refresh_required") {
		throw "Missing Hermes memory index should require refresh."
	}
} finally {
	if (Test-Path -LiteralPath $tempRoot -PathType Container) {
		Remove-Item -LiteralPath $tempRoot -Recurse -Force
	}
}

Write-Host "Hermes memory readiness checks passed."
