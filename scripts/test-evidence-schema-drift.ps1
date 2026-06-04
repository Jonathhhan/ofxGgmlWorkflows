param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Get-PythonStringCollection {
	param(
		[string]$Content,
		[string]$Name
	)

	if ($Content -notmatch "(?ms)^$Name\s*=\s*[\{\(](?<Block>.*?)[\}\)]") {
		throw "Could not find Python collection: $Name"
	}

	$values = @(
		foreach ($match in [regex]::Matches($Matches.Block, '"([^"]+)"')) {
			$match.Groups[1].Value
		}
	)

	if ($values.Count -eq 0) {
		throw "Python collection $Name did not contain string values"
	}

	return @($values | Sort-Object -Unique)
}

function Compare-StringSet {
	param(
		[string]$Label,
		[string[]]$Expected,
		[string[]]$Actual
	)

	$expectedSorted = @($Expected | Sort-Object -Unique)
	$actualSorted = @($Actual | Sort-Object -Unique)
	$missing = @($expectedSorted | Where-Object { $_ -notin $actualSorted })
	$extra = @($actualSorted | Where-Object { $_ -notin $expectedSorted })

	if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
		$message = "$Label drift detected."
		if ($missing.Count -gt 0) {
			$message += " Missing from validator: $($missing -join ', ')."
		}
		if ($extra.Count -gt 0) {
			$message += " Extra in validator: $($extra -join ', ')."
		}
		throw $message
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$schemaPath = Join-Path $repoRoot "schemas\evidence-v1.schema.json"
$validatorPath = Join-Path $repoRoot "scripts\validate-evidence.py"

Write-Step "Checking evidence schema and validator drift"

$schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
$validator = Get-Content -LiteralPath $validatorPath -Raw
$evidenceSchema = $schema.'$defs'.evidence

Compare-StringSet `
	-Label "Required fields" `
	-Expected @($evidenceSchema.required) `
	-Actual (Get-PythonStringCollection -Content $validator -Name "REQUIRED_FIELDS")

Compare-StringSet `
	-Label "Result enum" `
	-Expected @($evidenceSchema.properties.result.enum) `
	-Actual (Get-PythonStringCollection -Content $validator -Name "VALID_RESULTS")

Compare-StringSet `
	-Label "Certification level enum" `
	-Expected @($evidenceSchema.properties.certification_level.enum) `
	-Actual (Get-PythonStringCollection -Content $validator -Name "VALID_LEVELS")

Compare-StringSet `
	-Label "Tree state enum" `
	-Expected @($evidenceSchema.properties.tree_state.enum) `
	-Actual (Get-PythonStringCollection -Content $validator -Name "VALID_TREE_STATES")

Compare-StringSet `
	-Label "Certification level ordering" `
	-Expected @($evidenceSchema.properties.certification_level.enum) `
	-Actual (Get-PythonStringCollection -Content $validator -Name "LEVEL_ORDER")

Write-Step "Evidence schema drift checks passed"
