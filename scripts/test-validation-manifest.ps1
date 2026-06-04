param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Resolve-RepoPath {
	param([string]$Path)
	return Join-Path $repoRoot ($Path -replace '/', '\')
}

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

function Assert-FileContains {
	param(
		[string]$Path,
		[string]$Pattern,
		[string]$Label
	)

	$content = Get-Content -LiteralPath $Path -Raw
	if ($content -notmatch $Pattern) {
		throw "$Label did not contain expected pattern from manifest: $Pattern"
	}
}

function Assert-ExactFileInventory {
	param(
		[string]$DirectoryPath,
		[string]$Filter,
		[string[]]$ExpectedFiles,
		[string]$Label
	)

	$expected = @($ExpectedFiles | Sort-Object)
	$actual = @(Get-ChildItem -LiteralPath $DirectoryPath -Filter $Filter -File | Select-Object -ExpandProperty Name | Sort-Object)
	$missing = @($expected | Where-Object { $_ -notin $actual })
	$extra = @($actual | Where-Object { $_ -notin $expected })
	if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
		$message = "$Label manifest drift detected."
		if ($missing.Count -gt 0) {
			$message += " Missing: $($missing -join ', ')."
		}
		if ($extra.Count -gt 0) {
			$message += " Extra: $($extra -join ', ')."
		}
		throw $message
	}
}

function Assert-NoBomInventory {
	param(
		[string]$DirectoryPath,
		[string[]]$FileNames,
		[string]$Label
	)

	foreach ($fileName in @($FileNames)) {
		Assert-NoBom (Join-Path $DirectoryPath $fileName) "$Label $fileName"
	}
}

function Assert-ManifestTopLevelProperties {
	param(
		[object]$Manifest,
		[string[]]$ExpectedProperties
	)

	$expected = @($ExpectedProperties | Sort-Object)
	$actual = @($Manifest.PSObject.Properties.Name | Sort-Object)
	$missing = @($expected | Where-Object { $_ -notin $actual })
	$extra = @($actual | Where-Object { $_ -notin $expected })
	if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
		$message = "Validation manifest shape drift detected."
		if ($missing.Count -gt 0) {
			$message += " Missing properties: $($missing -join ', ')."
		}
		if ($extra.Count -gt 0) {
			$message += " Extra properties: $($extra -join ', ')."
		}
		throw $message
	}
}

function Assert-NonEmptyManifestArray {
	param(
		[object]$Manifest,
		[string]$PropertyName
	)

	$values = @($Manifest.$PropertyName)
	if ($values.Count -eq 0) {
		throw "Validation manifest property '$PropertyName' must be a non-empty array."
	}
}

function Assert-UniqueManifestArray {
	param(
		[object]$Manifest,
		[string]$PropertyName
	)

	Assert-UniqueManifestValues @($Manifest.$PropertyName) $PropertyName
}

function Assert-UniqueManifestValues {
	param(
		[string[]]$Values,
		[string]$Label
	)

	$values = @($Values)
	$duplicates = @($values | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
	if ($duplicates.Count -gt 0) {
		throw "Validation manifest '$Label' contains duplicate values: $($duplicates -join ', ')."
	}
}

function Assert-WorkflowSubset {
	param(
		[string[]]$Values,
		[string[]]$AllWorkflowFiles,
		[string]$Label
	)

	$unknown = @($Values | Where-Object { $_ -notin $AllWorkflowFiles })
	if ($unknown.Count -gt 0) {
		throw "$Label contains workflow names not listed in workflow_files: $($unknown -join ', ')."
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$workflowRoot = Join-Path $repoRoot ".github\workflows"
$evidenceFixtureRoot = Join-Path $repoRoot "tests\evidence"
$workflowFixtureRoot = Join-Path $repoRoot "tests\workflows"
$manifestPath = Join-Path $repoRoot "schemas\validation-manifest.json"

Write-Step "Checking validation manifest"

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

Assert-ManifestTopLevelProperties $manifest @(
	"coverage_checks",
	"evidence_fixture_files",
	"no_bom_paths",
	"report_workflow_patterns",
	"report_workflows",
	"required_paths",
	"required_reusable_workflow_patterns",
	"required_reusable_workflows",
	"runtime_workflow_patterns",
	"runtime_workflows",
	"workflow_files",
	"workflow_fixture_files",
	"workflow_fixture_pairs",
	"workflow_patterns",
	"workflow_profiles"
)

foreach ($propertyName in @(
	"coverage_checks",
	"evidence_fixture_files",
	"no_bom_paths",
	"report_workflow_patterns",
	"report_workflows",
	"required_paths",
	"required_reusable_workflow_patterns",
	"required_reusable_workflows",
	"runtime_workflow_patterns",
	"runtime_workflows",
	"workflow_files",
	"workflow_fixture_files",
	"workflow_fixture_pairs"
)) {
	Assert-NonEmptyManifestArray $manifest $propertyName
}

foreach ($propertyName in @(
	"evidence_fixture_files",
	"no_bom_paths",
	"report_workflow_patterns",
	"report_workflows",
	"required_reusable_workflow_patterns",
	"required_reusable_workflows",
	"runtime_workflow_patterns",
	"runtime_workflows",
	"workflow_files",
	"workflow_fixture_files"
)) {
	Assert-UniqueManifestArray $manifest $propertyName
}

Assert-UniqueManifestValues @($manifest.required_paths | Select-Object -ExpandProperty path) "required_paths.path"
Assert-UniqueManifestValues @($manifest.coverage_checks | Select-Object -ExpandProperty path) "coverage_checks.path"
Assert-UniqueManifestValues @($manifest.workflow_fixture_pairs | ForEach-Object { "$($_.advisory_fixture)|$($_.required_fixture)" }) "workflow_fixture_pairs"

foreach ($entry in @($manifest.required_paths)) {
	if ([string]::IsNullOrWhiteSpace($entry.path) -or [string]::IsNullOrWhiteSpace($entry.label)) {
		throw "Each required_paths entry must include non-empty path and label values."
	}
	$path = Resolve-RepoPath $entry.path
	if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
		throw "$($entry.label) was not found: $path"
	}
}

foreach ($pathValue in @($manifest.no_bom_paths)) {
	Assert-NoBom (Resolve-RepoPath $pathValue) $pathValue
}

Assert-ExactFileInventory $workflowRoot "*.yml" @($manifest.workflow_files) "Workflow"
Assert-ExactFileInventory $evidenceFixtureRoot "*.json" @($manifest.evidence_fixture_files) "Evidence fixture"
Assert-ExactFileInventory $workflowFixtureRoot "*.yml" @($manifest.workflow_fixture_files) "Workflow fixture"
Assert-NoBomInventory $workflowRoot @($manifest.workflow_files) "workflow"
Assert-NoBomInventory $evidenceFixtureRoot @($manifest.evidence_fixture_files) "evidence fixture"
Assert-NoBomInventory $workflowFixtureRoot @($manifest.workflow_fixture_files) "workflow fixture"

$workflowPatternNames = @($manifest.workflow_patterns.PSObject.Properties.Name)
Assert-WorkflowSubset @($manifest.report_workflows) @($manifest.workflow_files) "report_workflows"
Assert-WorkflowSubset @($manifest.runtime_workflows) @($manifest.workflow_files) "runtime_workflows"
Assert-WorkflowSubset @($manifest.required_reusable_workflows) @($manifest.workflow_files) "required_reusable_workflows"
Assert-WorkflowSubset $workflowPatternNames @($manifest.workflow_files) "workflow_patterns"

foreach ($pair in @($manifest.workflow_fixture_pairs)) {
	if (
		[string]::IsNullOrWhiteSpace($pair.advisory_fixture) -or
		[string]::IsNullOrWhiteSpace($pair.required_fixture) -or
		[string]::IsNullOrWhiteSpace($pair.workflow) -or
		@($pair.required_inputs).Count -eq 0
	) {
		throw "Each workflow_fixture_pairs entry must include advisory_fixture, required_fixture, workflow, and at least one required input."
	}
	if ($pair.advisory_fixture -notin @($manifest.workflow_fixture_files)) {
		throw "workflow_fixture_pairs references unknown advisory fixture: $($pair.advisory_fixture)"
	}
	if ($pair.required_fixture -notin @($manifest.workflow_fixture_files)) {
		throw "workflow_fixture_pairs references unknown required fixture: $($pair.required_fixture)"
	}
	if ($pair.workflow -notin @($manifest.workflow_files)) {
		throw "workflow_fixture_pairs references unknown workflow: $($pair.workflow)"
	}
	Assert-UniqueManifestValues @($pair.required_inputs) "workflow_fixture_pairs[$($pair.advisory_fixture)].required_inputs"
}

foreach ($profileEntry in $manifest.workflow_profiles.PSObject.Properties) {
	$profileInput = $profileEntry.Name
	$contract = $profileEntry.Value
	if (
		[string]::IsNullOrWhiteSpace($contract.workflow) -or
		@($contract.profiles).Count -eq 0 -or
		@($contract.fixture_profiles).Count -eq 0
	) {
		throw "workflow_profiles.$profileInput must include workflow, profiles, and fixture_profiles."
	}
	if ($contract.workflow -notin @($manifest.workflow_files)) {
		throw "workflow_profiles.$profileInput references unknown workflow: $($contract.workflow)"
	}
	Assert-UniqueManifestValues @($contract.profiles) "workflow_profiles.$profileInput.profiles"
	Assert-UniqueManifestValues @($contract.fixture_profiles | Select-Object -ExpandProperty fixture) "workflow_profiles.$profileInput.fixture_profiles.fixture"

	foreach ($fixtureProfile in @($contract.fixture_profiles)) {
		if ([string]::IsNullOrWhiteSpace($fixtureProfile.fixture) -or [string]::IsNullOrWhiteSpace($fixtureProfile.profile)) {
			throw "workflow_profiles.$profileInput fixture_profiles entries must include fixture and profile."
		}
		if ($fixtureProfile.fixture -notin @($manifest.workflow_fixture_files)) {
			throw "workflow_profiles.$profileInput references unknown fixture: $($fixtureProfile.fixture)"
		}
		if ($fixtureProfile.profile -notin @($contract.profiles)) {
			throw "workflow_profiles.$profileInput references unknown profile '$($fixtureProfile.profile)' for fixture $($fixtureProfile.fixture)"
		}
	}
}

foreach ($check in @($manifest.coverage_checks)) {
	if ([string]::IsNullOrWhiteSpace($check.path) -or [string]::IsNullOrWhiteSpace($check.label) -or @($check.patterns).Count -eq 0) {
		throw "Each coverage_checks entry must include path, label, and at least one pattern."
	}
	$path = Resolve-RepoPath $check.path
	foreach ($pattern in @($check.patterns)) {
		Assert-FileContains $path $pattern $check.label
	}
}

foreach ($workflowEntry in $manifest.workflow_patterns.PSObject.Properties) {
	$path = Join-Path $workflowRoot $workflowEntry.Name
	foreach ($pattern in @($workflowEntry.Value)) {
		Assert-FileContains $path $pattern $workflowEntry.Name
	}
}

foreach ($workflowName in @($manifest.report_workflows)) {
	$path = Join-Path $workflowRoot $workflowName
	foreach ($pattern in @($manifest.report_workflow_patterns)) {
		Assert-FileContains $path $pattern $workflowName
	}
}

foreach ($workflowName in @($manifest.runtime_workflows)) {
	$path = Join-Path $workflowRoot $workflowName
	foreach ($pattern in @($manifest.runtime_workflow_patterns)) {
		Assert-FileContains $path $pattern $workflowName
	}
}

foreach ($workflowName in @($manifest.required_reusable_workflows)) {
	$path = Join-Path $workflowRoot $workflowName
	foreach ($pattern in @($manifest.required_reusable_workflow_patterns)) {
		Assert-FileContains $path $pattern $workflowName
	}
}

Write-Step "Validation manifest checks passed"
