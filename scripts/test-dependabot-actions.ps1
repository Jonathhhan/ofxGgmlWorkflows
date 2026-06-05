param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Assert-Contains {
	param(
		[string]$Content,
		[string]$Pattern,
		[string]$Label
	)

	if ($Content -notmatch $Pattern) {
		throw "Dependabot config is missing $Label."
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$dependabotPath = Join-Path $repoRoot ".github\dependabot.yml"

Write-Step "Checking Dependabot GitHub Actions coverage"

if (!(Test-Path -LiteralPath $dependabotPath -PathType Leaf)) {
	throw "Dependabot config was not found: $dependabotPath"
}

$content = Get-Content -LiteralPath $dependabotPath -Raw
Assert-Contains $content '(?m)^version:\s*2\s*$' "version 2"
Assert-Contains $content '(?m)^\s*-\s*package-ecosystem:\s*"?github-actions"?\s*$' "github-actions ecosystem"
Assert-Contains $content '(?m)^\s*directory:\s*"?/"?\s*$' "root workflow directory"
Assert-Contains $content '(?m)^\s*interval:\s*"?weekly"?\s*$' "weekly schedule"
Assert-Contains $content '(?m)^\s*open-pull-requests-limit:\s*[1-9][0-9]*\s*$' "open pull request limit"
Assert-Contains $content '(?m)^\s*groups:\s*$' "grouped updates"
Assert-Contains $content '(?m)^\s*github-actions:\s*$' "github-actions update group"

Write-Step "Dependabot GitHub Actions checks passed"
