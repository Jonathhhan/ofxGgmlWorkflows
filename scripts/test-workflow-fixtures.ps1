param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Get-ReusableWorkflowInputs {
	param([string]$Path)

	$content = Get-Content -LiteralPath $Path -Raw
	$inputs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
	if ($content -match '(?ms)^\s+inputs:\s*\r?\n(?<Block>.*?)(?=^jobs:)') {
		$block = $Matches.Block
		foreach ($match in [regex]::Matches($block, '(?m)^\s{6}([A-Za-z0-9_-]+):\s*$')) {
			[void]$inputs.Add($match.Groups[1].Value)
		}
	}
	return $inputs
}

function Get-WorkflowFixtureJobs {
	param([string]$Path)

	$content = Get-Content -LiteralPath $Path -Raw
	$matches = [regex]::Matches(
		$content,
		'(?ms)^\s{2}[A-Za-z0-9_-]+:\s*\r?\n(?<Block>.*?)(?=^\s{2}[A-Za-z0-9_-]+:\s*\r?\n|\z)'
	)
	$jobs = New-Object System.Collections.Generic.List[object]

	foreach ($match in $matches) {
		$block = $match.Groups["Block"].Value
		if ($block -notmatch '(?m)^\s{4}uses:\s*Jonathhhan/ofxGgmlWorkflows/\.github/workflows/(?<Workflow>[^@\s]+)@(?<Ref>\S+)\s*$') {
			continue
		}

		$workflow = $Matches.Workflow
		$ref = $Matches.Ref
		$withKeys = New-Object System.Collections.Generic.List[string]
		$withValues = @{}
		if ($block -match '(?ms)^\s{4}with:\s*\r?\n(?<WithBlock>.*?)(?=^\s{4}[A-Za-z0-9_-]+:|\z)') {
			foreach ($withMatch in [regex]::Matches($Matches.WithBlock, '(?m)^\s{6}([A-Za-z0-9_-]+):\s*(?:"([^"]*)"|''([^'']*)''|([^#\r\n]+))?\s*(?:#.*)?$')) {
				$key = $withMatch.Groups[1].Value
				$value = ""
				foreach ($groupIndex in @(2, 3, 4)) {
					if ($withMatch.Groups[$groupIndex].Success) {
						$value = $withMatch.Groups[$groupIndex].Value.Trim()
						break
					}
				}
				$withKeys.Add($key)
				$withValues[$key] = $value
			}
		}

		$jobs.Add([pscustomobject]@{
			Workflow = $workflow
			Ref = $ref
			Inputs = @($withKeys.ToArray())
			InputValues = $withValues
		})
	}

	return $jobs.ToArray()
}

function Assert-FixtureInputValue {
	param(
		[hashtable]$FixtureJobsByName,
		[string]$FixtureName,
		[string]$InputName,
		[string]$ExpectedValue
	)

	$jobs = @($FixtureJobsByName[$FixtureName])
	if ($jobs.Count -ne 1) {
		throw "$FixtureName should contain exactly one reusable workflow job"
	}
	if (!$jobs[0].InputValues.ContainsKey($InputName)) {
		throw "$FixtureName is missing expected input: $InputName"
	}
	$actualValue = $jobs[0].InputValues[$InputName]
	if ($actualValue -ne $ExpectedValue) {
		throw "$FixtureName expected $InputName to be '$ExpectedValue', found '$actualValue'"
	}
}

function Assert-FixturePair {
	param(
		[hashtable]$FixtureJobsByName,
		[string]$AdvisoryFixture,
		[string]$RequiredFixture,
		[string]$ExpectedWorkflow,
		[string[]]$RequiredInputs
	)

	$advisoryJobs = @($FixtureJobsByName[$AdvisoryFixture])
	$requiredJobs = @($FixtureJobsByName[$RequiredFixture])
	if ($advisoryJobs.Count -ne 1 -or $requiredJobs.Count -ne 1) {
		throw "$AdvisoryFixture and $RequiredFixture should each contain exactly one reusable workflow job"
	}
	if ($advisoryJobs[0].Workflow -ne $ExpectedWorkflow -or $requiredJobs[0].Workflow -ne $ExpectedWorkflow) {
		throw "$AdvisoryFixture and $RequiredFixture should both call $ExpectedWorkflow"
	}

	foreach ($inputName in $RequiredInputs) {
		Assert-FixtureInputValue $FixtureJobsByName $AdvisoryFixture $inputName "false"
		Assert-FixtureInputValue $FixtureJobsByName $RequiredFixture $inputName "true"
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$workflowRoot = Join-Path $repoRoot ".github\workflows"
$fixtureRoot = Join-Path $repoRoot "tests\workflows"
$manifestPath = Join-Path $repoRoot "schemas\validation-manifest.json"

Write-Step "Checking reusable workflow caller fixtures"

if (!(Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
	throw "workflow fixture directory was not found: $fixtureRoot"
}

$fixtureFiles = @(Get-ChildItem -LiteralPath $fixtureRoot -Filter "*.yml" -File)
if ($fixtureFiles.Count -eq 0) {
	throw "No workflow fixture files found in $fixtureRoot"
}

$workflowInputs = @{}
foreach ($workflow in Get-ChildItem -LiteralPath $workflowRoot -Filter "*.yml" -File) {
	$workflowInputs[$workflow.Name] = Get-ReusableWorkflowInputs -Path $workflow.FullName
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

$checkedJobs = 0
$fixtureJobsByName = @{}
foreach ($fixture in $fixtureFiles) {
	$jobs = @(Get-WorkflowFixtureJobs -Path $fixture.FullName)
	if ($jobs.Count -eq 0) {
		throw "$($fixture.Name) does not contain a reusable ofxGgmlWorkflows job"
	}
	$fixtureJobsByName[$fixture.Name] = $jobs

	foreach ($job in $jobs) {
		$checkedJobs += 1
		if (!$workflowInputs.ContainsKey($job.Workflow)) {
			throw "$($fixture.Name) references unknown reusable workflow: $($job.Workflow)"
		}
		if ($job.Ref -ne "main") {
			throw "$($fixture.Name) should pin examples to @main, found @$($job.Ref)"
		}

		$allowedInputs = $workflowInputs[$job.Workflow]
		foreach ($input in $job.Inputs) {
			if (!$allowedInputs.Contains($input)) {
				throw "$($fixture.Name) passes unsupported input '$input' to $($job.Workflow)"
			}
		}
	}
}

foreach ($pair in @($manifest.workflow_fixture_pairs)) {
	Assert-FixturePair $fixtureJobsByName $pair.advisory_fixture $pair.required_fixture $pair.workflow @($pair.required_inputs)
}

Write-Step "Workflow fixture tests passed ($checkedJobs reusable job contracts checked)"
