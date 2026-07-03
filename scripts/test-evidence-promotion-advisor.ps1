param()

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$advisor = Join-Path $scriptRoot "write-evidence-promotion-advice.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ofxggml-promotion-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
	$evidencePath = Join-Path $tempRoot "sam3-runtime-evidence.json"
	$reportPath = Join-Path $tempRoot "promotion.md"
	$jsonPath = Join-Path $tempRoot "promotion.json"
	$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
	$evidence = [ordered] @{
		schema_version = "1"
		repo = "ofxGgmlSam"
		lane = "segmentation"
		commit_sha = "0123456789abcdef"
		workflow_name = "sam3-runtime-smoke"
		runner_os = "Windows"
		backend = "cpu"
		result = "pass"
		timestamp = $timestamp
		artifact_path = ".sam3-runtime-smoke.json"
		producer = "write-sam3-runtime-evidence.ps1"
		producer_version = "1.0.0"
		command = "scripts/run-sam3-evidence-pilot.bat -Backend cpu"
		command_exit_code = 0
		tree_state = "clean"
		subject_paths = @("scripts/run-sam3-runtime-smoke.ps1")
		certification_level = "runtime-certified"
		started_at = $timestamp
		completed_at = $timestamp
		workflow_run_id = "123"
		workflow_sha = "0123456789abcdef"
		job_name = "evidence"
		artifact_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	}
	$evidence | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $evidencePath

	& $advisor `
		-EvidencePath $evidencePath `
		-CurrentProfile "advisory" `
		-CandidateProfile "schema" `
		-RequiredCleanRuns 3 `
		-ObservedCleanRuns 3 `
		-MinimumQualityScore 85 `
		-RequiredBackend "cpu" `
		-RequiredResult "pass" `
		-MinimumCertificationLevel "smoke-built" `
		-ExpectedCommitSha "0123456789abcdef" `
		-MaxEvidenceAgeHours 24 `
		-ReportPath $reportPath `
		-JsonPath $jsonPath
	if ($LASTEXITCODE -ne 0) { throw "Promotion advisor failed for valid evidence." }
	if (!(Test-Path -LiteralPath $reportPath -PathType Leaf)) { throw "Promotion advisor did not write a Markdown report." }
	if (!(Test-Path -LiteralPath $jsonPath -PathType Leaf)) { throw "Promotion advisor did not write JSON output." }
	$result = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
	if ($result.recommendation -ne "promote to fresh-current-sha") {
		throw "Expected recommendation 'promote to fresh-current-sha', found '$($result.recommendation)'"
	}
	if ($result.schema_valid -ne $true -or $result.matching_record -ne $true) {
		throw "Promotion advisor did not mark valid evidence as schema-valid and matching."
	}

	$lowRunJson = Join-Path $tempRoot "promotion-low-runs.json"
	& $advisor `
		-EvidencePath $evidencePath `
		-RequiredCleanRuns 3 `
		-ObservedCleanRuns 1 `
		-MinimumQualityScore 85 `
		-RequiredBackend "cpu" `
		-RequiredResult "pass" `
		-MinimumCertificationLevel "smoke-built" `
		-ExpectedCommitSha "0123456789abcdef" `
		-MaxEvidenceAgeHours 24 `
		-ReportPath (Join-Path $tempRoot "promotion-low-runs.md") `
		-JsonPath $lowRunJson
	if ($LASTEXITCODE -ne 0) { throw "Promotion advisor failed for low clean-run evidence." }
	$lowRunResult = Get-Content -LiteralPath $lowRunJson -Raw | ConvertFrom-Json
	if ($lowRunResult.recommendation -ne "stay advisory") {
		throw "Expected low clean runs to stay advisory, found '$($lowRunResult.recommendation)'"
	}
	$invalidSchemaPath = Join-Path $tempRoot "invalid-schema-evidence.json"
	$invalidSchema = [ordered] @{}
	foreach ($entry in $evidence.GetEnumerator()) { $invalidSchema[$entry.Key] = $entry.Value }
	$invalidSchema.schema_version = "2"
	$invalidSchema | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $invalidSchemaPath
	$invalidSchemaJson = Join-Path $tempRoot "promotion-invalid-schema.json"
	& $advisor `
		-EvidencePath $invalidSchemaPath `
		-RequiredCleanRuns 3 `
		-ObservedCleanRuns 3 `
		-MinimumQualityScore 85 `
		-RequiredBackend "cpu" `
		-RequiredResult "pass" `
		-MinimumCertificationLevel "smoke-built" `
		-ExpectedCommitSha "0123456789abcdef" `
		-MaxEvidenceAgeHours 24 `
		-ReportPath (Join-Path $tempRoot "promotion-invalid-schema.md") `
		-JsonPath $invalidSchemaJson
	if ($LASTEXITCODE -ne 0) { throw "Promotion advisor failed for invalid-schema evidence." }
	$invalidSchemaResult = Get-Content -LiteralPath $invalidSchemaJson -Raw | ConvertFrom-Json
	if ($invalidSchemaResult.schema_valid -ne $false -or $invalidSchemaResult.recommendation -ne "stay advisory") {
		throw "Invalid-schema evidence must stay advisory and report schema_valid=false."
	}

	$splitEvidencePath = Join-Path $tempRoot "split-requirements-evidence.json"
	$staleTimestamp = (Get-Date).ToUniversalTime().AddDays(-2).ToString("yyyy-MM-ddTHH:mm:ssZ")
	$currentButWrongBackend = [ordered] @{}
	$freshButWrongSha = [ordered] @{}
	foreach ($entry in $evidence.GetEnumerator()) {
		$currentButWrongBackend[$entry.Key] = $entry.Value
		$freshButWrongSha[$entry.Key] = $entry.Value
	}
	$currentButWrongBackend.backend = "cuda"
	$currentButWrongBackend.timestamp = $staleTimestamp
	$freshButWrongSha.commit_sha = "fedcba9876543210"
	@($currentButWrongBackend, $freshButWrongSha) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $splitEvidencePath
	$splitEvidenceJson = Join-Path $tempRoot "promotion-split-requirements.json"
	& $advisor `
		-EvidencePath $splitEvidencePath `
		-RequiredCleanRuns 3 `
		-ObservedCleanRuns 3 `
		-MinimumQualityScore 85 `
		-RequiredBackend "cpu" `
		-RequiredResult "pass" `
		-MinimumCertificationLevel "smoke-built" `
		-ExpectedCommitSha "0123456789abcdef" `
		-MaxEvidenceAgeHours 24 `
		-ReportPath (Join-Path $tempRoot "promotion-split-requirements.md") `
		-JsonPath $splitEvidenceJson
	if ($LASTEXITCODE -ne 0) { throw "Promotion advisor failed for split-requirements evidence." }
	$splitEvidenceResult = Get-Content -LiteralPath $splitEvidenceJson -Raw | ConvertFrom-Json
	if ($splitEvidenceResult.current_sha -ne $false -or $splitEvidenceResult.fresh -ne $false) {
		throw "Separate records must not jointly satisfy current-SHA and freshness requirements."
	}
	if ($splitEvidenceResult.recommendation -eq "promote to fresh-current-sha" -or $splitEvidenceResult.recommendation -eq "ready for release-gate") {
		throw "Split-requirements evidence received an unsafe promotion recommendation."
	}

} finally {
	Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Evidence promotion advisor tests passed"
