param(
	[string]$IndexPath = "build\hermes-memory\hermes-memory-index.json",
	[int]$MaxAgeHours = 24,
	[switch]$Json,
	[switch]$Strict
)

$ErrorActionPreference = "Stop"

function Get-GitValue {
	param([string[]]$Arguments)

	try {
		$value = & git @Arguments 2>$null
		if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrWhiteSpace([string]$value)) {
			return ([string]$value).Trim()
		}
	} catch {
	}
	return "unknown"
}

function Get-GitTreeState {
	try {
		$status = & git status --porcelain 2>$null
		if ($LASTEXITCODE -ne 0) {
			return "unknown"
		}
		if (@($status).Count -gt 0) {
			return "dirty"
		}
		return "clean"
	} catch {
		return "unknown"
	}
}

function Resolve-RepoPath {
	param([string]$Path)

	if ([System.IO.Path]::IsPathRooted($Path)) {
		return $Path
	}
	return Join-Path $repoRoot $Path
}

function Add-Issue {
	param([string]$Message)
	$script:issues += $Message
}

function Add-Warning {
	param([string]$Message)
	$script:warnings += $Message
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$resolvedIndexPath = Resolve-RepoPath $IndexPath
$currentCommitSha = Get-GitValue @("rev-parse", "--short=12", "HEAD")
$currentTreeState = Get-GitTreeState
$issues = @()
$warnings = @()
$recordCount = 0
$changedSourceCount = 0
$ageHours = $null
$indexCommitSha = ""
$indexTreeState = ""
$generatedAt = ""

if (!(Test-Path -LiteralPath $resolvedIndexPath -PathType Leaf)) {
	Add-Issue "Memory index was not found: $resolvedIndexPath"
} else {
	try {
		$index = Get-Content -LiteralPath $resolvedIndexPath -Raw | ConvertFrom-Json
	} catch {
		Add-Issue "Memory index is not valid JSON: $($_.Exception.Message)"
	}

	if ($issues.Count -eq 0) {
		if ([int]$index.schema_version -ne 1) {
			Add-Issue "Memory index schema_version must be 1."
		}

		$generatedAt = [string]$index.generated_at
		$indexCommitSha = [string]$index.commit_sha
		$indexTreeState = [string]$index.tree_state

		if ([string]::IsNullOrWhiteSpace($generatedAt)) {
			Add-Issue "Memory index is missing generated_at."
		} else {
			try {
				$generated = [DateTimeOffset]::Parse($generatedAt)
				$ageHours = [Math]::Round(([DateTimeOffset]::UtcNow - $generated.ToUniversalTime()).TotalHours, 2)
				if ($ageHours -gt $MaxAgeHours) {
					Add-Issue "Memory index is stale: $ageHours hours old, limit is $MaxAgeHours hours."
				}
			} catch {
				Add-Issue "Memory index generated_at is not a valid timestamp: $generatedAt"
			}
		}

		if ([string]::IsNullOrWhiteSpace($indexCommitSha) -or $indexCommitSha -eq "unknown") {
			Add-Issue "Memory index is missing commit_sha."
		} elseif ($currentCommitSha -ne "unknown" -and $indexCommitSha -ne $currentCommitSha) {
			Add-Issue "Memory index commit_sha $indexCommitSha does not match current checkout $currentCommitSha."
		}

		if ($indexTreeState -eq "dirty") {
			Add-Warning "Memory index was generated from a dirty tree; read touched source files directly before acting."
		}
		if ($currentTreeState -eq "dirty") {
			Add-Warning "Current checkout is dirty; report dirty-repo caveats in the handoff."
		}

		$records = @($index.records)
		$recordCount = $records.Count
		if ($recordCount -eq 0) {
			Add-Issue "Memory index has no records."
		}

		$ids = @{}
		foreach ($record in $records) {
			$id = [string]$record.id
			if ([string]::IsNullOrWhiteSpace($id)) {
				Add-Issue "Memory record is missing id."
			} elseif ($ids.ContainsKey($id)) {
				Add-Issue "Memory record id is duplicated: $id"
			} else {
				$ids[$id] = $true
			}

			foreach ($property in @("source_path", "source_sha256", "source_modified_at", "repo", "lane", "source_type", "freshness", "summary")) {
				if ([string]::IsNullOrWhiteSpace([string]$record.$property)) {
					Add-Issue "Memory record $id is missing $property."
				}
			}

			$tags = @($record.retrieval_tags)
			if ($tags.Count -eq 0) {
				Add-Issue "Memory record $id is missing retrieval_tags."
			}

			if (![string]::IsNullOrWhiteSpace([string]$record.source_path)) {
				$sourcePath = Resolve-RepoPath ([string]$record.source_path -replace '/', '\')
				if (!(Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
					Add-Issue "Memory record $id source_path does not exist: $($record.source_path)"
				} else {
					if (![string]::IsNullOrWhiteSpace([string]$record.source_sha256)) {
						$currentHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
						if ($currentHash -ne ([string]$record.source_sha256).ToLowerInvariant()) {
							$changedSourceCount += 1
							Add-Issue "Memory record $id source_sha256 does not match current source file."
						}
					}

					if (![string]::IsNullOrWhiteSpace([string]$record.source_modified_at)) {
						try {
							$recordModifiedAt = [DateTimeOffset]::Parse([string]$record.source_modified_at)
							$currentModifiedAt = (Get-Item -LiteralPath $sourcePath).LastWriteTimeUtc
							if ($currentModifiedAt -gt $recordModifiedAt.UtcDateTime.AddSeconds(1)) {
								Add-Issue "Memory record $id source file was modified after the index record."
							}
						} catch {
							Add-Issue "Memory record $id source_modified_at is not a valid timestamp: $($record.source_modified_at)"
						}
					}
				}
			}
		}
	}
}

$status = "ready"
if ($issues.Count -gt 0) {
	$status = "refresh_required"
} elseif ($warnings.Count -gt 0) {
	$status = "caution"
}

$report = [ordered]@{
	status = $status
	ready = ($issues.Count -eq 0)
	index_path = $resolvedIndexPath
	generated_at = $generatedAt
	age_hours = $ageHours
	max_age_hours = $MaxAgeHours
	index_commit_sha = $indexCommitSha
	current_commit_sha = $currentCommitSha
	index_tree_state = $indexTreeState
	current_tree_state = $currentTreeState
	record_count = $recordCount
	changed_source_count = $changedSourceCount
	issues = @($issues)
	warnings = @($warnings)
}

if ($Json) {
	$report | ConvertTo-Json -Depth 6
} else {
	Write-Host "Hermes memory status: $status"
	Write-Host "Index: $resolvedIndexPath"
	Write-Host "Records: $recordCount"
	if ($null -ne $ageHours) {
		Write-Host "Age hours: $ageHours / $MaxAgeHours"
	}
	foreach ($issue in $issues) {
		Write-Host "ISSUE: $issue"
	}
	foreach ($warning in $warnings) {
		Write-Host "WARNING: $warning"
	}
}

if ($Strict -and $issues.Count -gt 0) {
	throw "Hermes memory index is not ready: $($issues -join '; ')"
}
