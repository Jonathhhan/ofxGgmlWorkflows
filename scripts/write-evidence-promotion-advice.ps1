param(
	[string] $EvidencePath = "build/evidence/*.json",
	[string] $CurrentProfile = "advisory",
	[string] $CandidateProfile = "schema",
	[int] $RequiredCleanRuns = 3,
	[int] $ObservedCleanRuns = 0,
	[double] $MinimumQualityScore = 85,
	[string] $RequiredBackend = "",
	[string] $RequiredResult = "",
	[string] $MinimumCertificationLevel = "",
	[string] $ExpectedCommitSha = "",
	[double] $MaxEvidenceAgeHours = 0,
	[string] $ReportPath = "build/evidence/evidence-promotion.md",
	[string] $JsonPath = "build/evidence/evidence-promotion.json"
)

$ErrorActionPreference = "Stop"

$requiredFields = @(
	"schema_version",
	"repo",
	"lane",
	"commit_sha",
	"workflow_name",
	"runner_os",
	"backend",
	"result",
	"timestamp",
	"artifact_path"
)
$qualityFields = @(
	"producer",
	"producer_version",
	"command",
	"command_exit_code",
	"tree_state",
	"subject_paths",
	"certification_level",
	"started_at",
	"completed_at",
	"workflow_run_id",
	"workflow_sha",
	"job_name",
	"artifact_sha256"
)
$validResults = @("pass", "fail", "skipped", "not_certified")
$levelOrder = @{
	"declared" = 0
	"smoke-built" = 1
	"runtime-certified" = 2
	"release-gated" = 3
}

function Get-EvidenceFiles {
	param([string] $Path)
	$files = @(Resolve-Path -Path $Path -ErrorAction SilentlyContinue | ForEach-Object { $_.Path } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
	if ($files.Count -eq 0 -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
		$files = @((Resolve-Path -LiteralPath $Path).Path)
	}
	return @($files | Sort-Object -Unique)
}

function ConvertTo-RecordList {
	param([object] $Data)
	if ($Data -is [array]) { return @($Data) }
	return @($Data)
}

function Test-NonEmptyValue {
	param([object] $Value)
	if ($null -eq $Value) { return $false }
	if ($Value -is [string]) { return -not [string]::IsNullOrWhiteSpace($Value) }
	if ($Value -is [array]) { return $Value.Count -gt 0 }
	return $true
}

function Parse-IsoTimestamp {
	param([object] $Value)
	if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) { return $null }
	try { return ([datetimeoffset]::Parse($Value)).UtcDateTime } catch { return $null }
}

function Test-CommitMatch {
	param([string] $Actual, [string] $Expected)
	if ([string]::IsNullOrWhiteSpace($Expected)) { return $true }
	if ([string]::IsNullOrWhiteSpace($Actual)) { return $false }
	$actualLower = $Actual.ToLowerInvariant()
	$expectedLower = $Expected.ToLowerInvariant()
	return ($actualLower -eq $expectedLower -or $actualLower.StartsWith($expectedLower) -or $expectedLower.StartsWith($actualLower))
}

function Test-LevelAtLeast {
	param([string] $Actual, [string] $Minimum)
	if ([string]::IsNullOrWhiteSpace($Minimum)) { return $true }
	if (!$levelOrder.ContainsKey($Actual) -or !$levelOrder.ContainsKey($Minimum)) { return $false }
	return $levelOrder[$Actual] -ge $levelOrder[$Minimum]
}

function Get-Recommendation {
	param(
		[bool] $HasEvidence,
		[bool] $SchemaValid,
		[bool] $CurrentSha,
		[bool] $Fresh,
		[bool] $MatchingRecord,
		[bool] $QualityReady,
		[bool] $CleanRunsReady
	)
	if (-not $HasEvidence) { return "stay advisory" }
	if (-not $SchemaValid -or -not $MatchingRecord -or -not $QualityReady -or -not $CleanRunsReady) { return "stay advisory" }
	if (-not $CurrentSha) { return "promote to schema" }
	if (-not $Fresh) { return "promote to current-sha" }
	if ($CandidateProfile -in @("release", "fresh-current-sha", "certification")) { return "ready for release-gate" }
	return "promote to fresh-current-sha"
}

$evidenceFiles = Get-EvidenceFiles -Path $EvidencePath
$records = New-Object System.Collections.Generic.List[object]
$issues = New-Object System.Collections.Generic.List[string]
$qualityPassed = 0
$qualityTotal = 0
$matchingRecords = 0
$schemaValidRecords = 0
$currentShaRecords = 0
$freshRecords = 0

foreach ($file in $evidenceFiles) {
	try {
		$data = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
	} catch {
		$issues.Add("$file could not be parsed as JSON: $($_.Exception.Message)")
		continue
	}
	foreach ($record in ConvertTo-RecordList $data) {
		$records.Add($record)
		$recordSchemaValid = $true
		foreach ($field in $requiredFields) {
			if ($null -eq $record.PSObject.Properties[$field] -or -not (Test-NonEmptyValue $record.$field)) {
				$issues.Add("$file missing required field: $field")
				$recordSchemaValid = $false
			}
		}
		if ($record.PSObject.Properties["result"] -and $record.result -notin $validResults) {
			$issues.Add("$file result must be one of: $($validResults -join ', ')")
			$recordSchemaValid = $false
		}
		if ($record.PSObject.Properties["timestamp"] -and $null -eq (Parse-IsoTimestamp $record.timestamp)) {
			$issues.Add("$file timestamp must be ISO 8601")
			$recordSchemaValid = $false
		}
		if ($recordSchemaValid) { $schemaValidRecords++ }

		if (Test-CommitMatch ([string] $record.commit_sha) $ExpectedCommitSha) { $currentShaRecords++ }
		$timestamp = Parse-IsoTimestamp $record.timestamp
		$isFresh = $true
		if ($MaxEvidenceAgeHours -gt 0) {
			$isFresh = $false
			if ($timestamp) {
				$ageHours = ((Get-Date).ToUniversalTime() - $timestamp).TotalHours
				$isFresh = ($ageHours -ge 0 -and $ageHours -le $MaxEvidenceAgeHours)
			}
		}
		if ($isFresh) { $freshRecords++ }

		$backendMatches = [string]::IsNullOrWhiteSpace($RequiredBackend) -or $record.backend -eq $RequiredBackend
		$resultMatches = [string]::IsNullOrWhiteSpace($RequiredResult) -or $record.result -eq $RequiredResult
		$levelMatches = Test-LevelAtLeast ([string] $record.certification_level) $MinimumCertificationLevel
		if ($backendMatches -and $resultMatches -and $levelMatches) { $matchingRecords++ }

		foreach ($field in $requiredFields + $qualityFields) {
			$qualityTotal++
			if ($null -ne $record.PSObject.Properties[$field] -and (Test-NonEmptyValue $record.$field)) { $qualityPassed++ }
		}
	}
}

$hasEvidence = $records.Count -gt 0
$schemaValid = $hasEvidence -and $schemaValidRecords -eq $records.Count
$currentSha = $hasEvidence -and $currentShaRecords -gt 0
$fresh = $hasEvidence -and $freshRecords -gt 0
$matchingRecord = $hasEvidence -and $matchingRecords -gt 0
$qualityScore = if ($qualityTotal -gt 0) { [math]::Round(($qualityPassed / $qualityTotal) * 100, 2) } else { 0 }
$qualityReady = $qualityScore -ge $MinimumQualityScore
$cleanRunsReady = $ObservedCleanRuns -ge $RequiredCleanRuns
$recommendation = Get-Recommendation `
	-HasEvidence $hasEvidence `
	-SchemaValid $schemaValid `
	-CurrentSha $currentSha `
	-Fresh $fresh `
	-MatchingRecord $matchingRecord `
	-QualityReady $qualityReady `
	-CleanRunsReady $cleanRunsReady

$result = [ordered] @{
	recommendation = $recommendation
	current_profile = $CurrentProfile
	candidate_profile = $CandidateProfile
	evidence_path = $EvidencePath
	evidence_file_count = $evidenceFiles.Count
	record_count = $records.Count
	schema_valid = $schemaValid
	current_sha = $currentSha
	fresh = $fresh
	matching_record = $matchingRecord
	quality_score = $qualityScore
	minimum_quality_score = $MinimumQualityScore
	observed_clean_runs = $ObservedCleanRuns
	required_clean_runs = $RequiredCleanRuns
	issues = @($issues)
}

$jsonDirectory = Split-Path -Parent $JsonPath
if ($jsonDirectory -and !(Test-Path -LiteralPath $jsonDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $jsonDirectory -Force | Out-Null
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $JsonPath

$reportDirectory = Split-Path -Parent $ReportPath
if ($reportDirectory -and !(Test-Path -LiteralPath $reportDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}
$report = New-Object System.Collections.Generic.List[string]
$report.Add("# Evidence Promotion Advice")
$report.Add("")
$report.Add("- Recommendation: $recommendation")
$report.Add("- Current profile: $CurrentProfile")
$report.Add("- Candidate profile: $CandidateProfile")
$report.Add("- Evidence files: $($evidenceFiles.Count)")
$report.Add("- Evidence records: $($records.Count)")
$report.Add("- Quality score: $qualityScore%")
$report.Add("- Clean runs: $ObservedCleanRuns/$RequiredCleanRuns")
$report.Add("")
$report.Add("## Checks")
$report.Add("")
$report.Add("- schema_valid: $schemaValid")
$report.Add("- current_sha: $currentSha")
$report.Add("- fresh: $fresh")
$report.Add("- matching_record: $matchingRecord")
$report.Add("- quality_ready: $qualityReady")
$report.Add("- clean_runs_ready: $cleanRunsReady")
if ($issues.Count -gt 0) {
	$report.Add("")
	$report.Add("## Issues")
	$report.Add("")
	foreach ($issue in $issues) { $report.Add("- $issue") }
}
$report -join [Environment]::NewLine | Set-Content -LiteralPath $ReportPath

Write-Host "Evidence promotion recommendation: $recommendation"
Write-Host "Wrote promotion report: $ReportPath"
Write-Host "Wrote promotion JSON: $JsonPath"
exit 0
