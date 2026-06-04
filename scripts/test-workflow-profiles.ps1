param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Assert-FileContains {
	param(
		[string]$Path,
		[string]$Pattern,
		[string]$Label
	)

	$content = Get-Content -LiteralPath $Path -Raw
	if ($content -notmatch $Pattern) {
		throw "$Label did not contain expected profile pattern: $Pattern"
	}
}

function Assert-ProfileList {
	param(
		[string]$Path,
		[string]$ProfileInput,
		[string[]]$ExpectedProfiles,
		[string]$Label
	)

	$content = Get-Content -LiteralPath $Path -Raw
	$allowedPattern = "Allowed values: $([regex]::Escape(($ExpectedProfiles -join ', ')))"
	if ($content -notmatch $allowedPattern) {
		throw "$Label does not advertise the expected $ProfileInput values: $($ExpectedProfiles -join ', ')"
	}

	foreach ($profile in $ExpectedProfiles) {
		if ($content -notmatch "(^|[|, ])$([regex]::Escape($profile))([)|, ]|$)") {
			throw "$Label does not contain expected $ProfileInput value: $profile"
		}
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$workflowRoot = Join-Path $repoRoot ".github\workflows"
$fixtureRoot = Join-Path $repoRoot "tests\workflows"
$manifestPath = Join-Path $repoRoot "schemas\validation-manifest.json"

Write-Step "Checking workflow rollout profiles"

$readme = Join-Path $repoRoot "README.md"
$adoptionDocs = Join-Path $repoRoot "docs\workflow-adoption.md"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

$evidenceProfileContract = $manifest.workflow_profiles.evidence_profile
$releaseProfileContract = $manifest.workflow_profiles.release_profile
$evidenceWorkflow = Join-Path $workflowRoot $evidenceProfileContract.workflow
$releaseWorkflow = Join-Path $workflowRoot $releaseProfileContract.workflow
$evidenceProfiles = @($evidenceProfileContract.profiles)
$releaseProfiles = @($releaseProfileContract.profiles)

Assert-ProfileList $evidenceWorkflow "evidence_profile" $evidenceProfiles "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "evidence_profile:" "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "default: custom" "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "fresh-current-sha\|certification\|release" "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "resolved_require_schema_valid" "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "resolved_require_current_sha" "evidence-validation.yml"
Assert-FileContains $evidenceWorkflow "resolved_require_freshness" "evidence-validation.yml"

Assert-ProfileList $releaseWorkflow "release_profile" $releaseProfiles "release-gate.yml"
Assert-FileContains $releaseWorkflow "release_profile:" "release-gate.yml"
Assert-FileContains $releaseWorkflow "default: custom" "release-gate.yml"
Assert-FileContains $releaseWorkflow "custom\|evidence" "release-gate.yml report profile branch"
Assert-FileContains $releaseWorkflow "reports\|release" "release-gate.yml report profile branch"
Assert-FileContains $releaseWorkflow "custom\|reports" "release-gate.yml evidence profile branch"
Assert-FileContains $releaseWorkflow "resolved_require_release_readiness_score" "release-gate.yml"
Assert-FileContains $releaseWorkflow "resolved_require_evidence_schema_valid" "release-gate.yml"
Assert-FileContains $releaseWorkflow "resolved_require_fresh_evidence" "release-gate.yml"

foreach ($fixtureProfile in @($evidenceProfileContract.fixture_profiles)) {
	Assert-FileContains (Join-Path $fixtureRoot $fixtureProfile.fixture) "evidence_profile:\s+$([regex]::Escape($fixtureProfile.profile))" $fixtureProfile.fixture
}

foreach ($fixtureProfile in @($releaseProfileContract.fixture_profiles)) {
	Assert-FileContains (Join-Path $fixtureRoot $fixtureProfile.fixture) "release_profile:\s+$([regex]::Escape($fixtureProfile.profile))" $fixtureProfile.fixture
}

foreach ($profile in $evidenceProfiles) {
	Assert-FileContains $readme $profile "README evidence profile docs"
	Assert-FileContains $adoptionDocs $profile "workflow adoption evidence profile docs"
}

foreach ($profile in $releaseProfiles) {
	Assert-FileContains $readme $profile "README release profile docs"
	Assert-FileContains $adoptionDocs $profile "workflow adoption release profile docs"
}

Write-Step "Workflow rollout profile checks passed"
