param()

$ErrorActionPreference = "Stop"

function Write-Step {
	param([string]$Message)
	Write-Host "==> $Message"
}

function Invoke-Validator {
	param(
		[string[]]$Arguments,
		[switch]$ExpectFailure,
		[string]$Label
	)

	& python $validator @Arguments
	$exitCode = $LASTEXITCODE

	if ($ExpectFailure) {
		if ($exitCode -eq 0) {
			throw "$Label unexpectedly passed"
		}
		return
	}

	if ($exitCode -ne 0) {
		throw "$Label failed with exit code $exitCode"
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$validator = Join-Path $repoRoot "scripts\validate-evidence.py"
$fixtureRoot = Join-Path $repoRoot "tests\evidence"
$reportPath = Join-Path $env:TEMP "ofxggml-evidence-quality.md"

Write-Step "Checking evidence validator fixtures"

Invoke-Validator -Label "full-quality evidence" -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "full-quality.json"),
	"--require-schema-valid", "true",
	"--require-current-sha", "true",
	"--expected-commit-sha", "0123456789abcdef0123456789abcdef01234567",
	"--required-backend", "cpu",
	"--required-result", "pass",
	"--minimum-certification-level", "smoke-built",
	"--quality-report-path", $reportPath
)

if (!(Test-Path -LiteralPath $reportPath -PathType Leaf)) {
	throw "Evidence quality report fixture was not written"
}

Invoke-Validator -Label "minimal advisory evidence" -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "minimal-quality.json"),
	"--require-schema-valid", "true"
)

Invoke-Validator -Label "array evidence records" -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "array-records.json"),
	"--require-schema-valid", "true",
	"--required-backend", "cpu",
	"--required-result", "pass",
	"--minimum-certification-level", "smoke-built"
)

Invoke-Validator -Label "invalid optional fields" -ExpectFailure -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "invalid-optional-fields.json"),
	"--require-schema-valid", "true"
)

Invoke-Validator -Label "stale evidence" -ExpectFailure -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "stale-evidence.json"),
	"--require-schema-valid", "true",
	"--require-freshness", "true",
	"--max-evidence-age-hours", "1"
)

Invoke-Validator -Label "mismatched SHA" -ExpectFailure -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "mismatched-sha.json"),
	"--require-schema-valid", "true",
	"--require-current-sha", "true",
	"--expected-commit-sha", "0123456789abcdef0123456789abcdef01234567"
)

Invoke-Validator -Label "bad certification level" -ExpectFailure -Arguments @(
	"--evidence-path", (Join-Path $fixtureRoot "bad-certification-level.json"),
	"--require-schema-valid", "true"
)

Write-Step "Evidence validator fixture tests passed"
