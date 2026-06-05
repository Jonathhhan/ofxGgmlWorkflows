$ErrorActionPreference = "Stop"

function Assert-NonEmptyString {
	param(
		[string]$Value,
		[string]$Label
	)

	if ([string]::IsNullOrWhiteSpace($Value)) {
		throw "$Label must be a non-empty string."
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$schemaPath = Join-Path $repoRoot "schemas\hermes-memory-v1.schema.json"
$writerPath = Join-Path $repoRoot "scripts\write-hermes-memory-index.ps1"

if (!(Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
	throw "Hermes memory schema was not found: $schemaPath"
}
if (!(Test-Path -LiteralPath $writerPath -PathType Leaf)) {
	throw "Hermes memory writer was not found: $writerPath"
}

$schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
if ($schema.title -ne "Hermes Memory Index v1") {
	throw "Hermes memory schema returned the wrong title."
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ofxggml-hermes-memory-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$indexPath = Join-Path $tempRoot "hermes-memory-index.json"

try {
	& $writerPath -OutputPath $indexPath | Out-Null
	$index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json

	if ([int]$index.schema_version -ne 1) {
		throw "Hermes memory index schema_version must be 1."
	}
	Assert-NonEmptyString ([string]$index.generated_at) "generated_at"
	Assert-NonEmptyString ([string]$index.repo) "repo"
	Assert-NonEmptyString ([string]$index.commit_sha) "commit_sha"
	Assert-NonEmptyString ([string]$index.tree_state) "tree_state"
	if ([string]$index.tree_state -notin @("clean", "dirty", "unknown", "generated-only")) {
		throw "Hermes memory index tree_state is not allowed: $($index.tree_state)"
	}

	$records = @($index.records)
	if ($records.Count -lt 12) {
		throw "Hermes memory index should include at least 12 source-grounded records."
	}

	$ids = @{}
	$allTags = @()
	foreach ($record in $records) {
		foreach ($property in @("id", "source_path", "repo", "lane", "source_type", "freshness", "summary")) {
			Assert-NonEmptyString ([string]$record.$property) "record.$property"
		}

		$id = [string]$record.id
		if ($ids.ContainsKey($id)) {
			throw "Hermes memory record id is duplicated: $id"
		}
		$ids[$id] = $true

		$sourcePath = Join-Path $repoRoot ([string]$record.source_path -replace '/', '\')
		if (!(Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
			throw "Hermes memory record source_path does not exist: $($record.source_path)"
		}

		if ([string]$record.source_type -notin @("instruction", "workflow", "runtime", "evidence", "validation", "planning", "release", "security", "example", "memory")) {
			throw "Hermes memory record has unsupported source_type: $($record.source_type)"
		}

		$tags = @($record.retrieval_tags)
		if ($tags.Count -eq 0) {
			throw "Hermes memory record $id must include retrieval_tags."
		}
		$allTags += $tags
	}

	foreach ($requiredTag in @("operating-loop", "evidence-schema", "workflow-security", "validation", "memory-contract")) {
		if ($requiredTag -notin $allTags) {
			throw "Hermes memory index is missing required retrieval tag: $requiredTag"
		}
	}
} finally {
	if (Test-Path -LiteralPath $tempRoot -PathType Container) {
		Remove-Item -LiteralPath $tempRoot -Recurse -Force
	}
}

Write-Host "Hermes memory index checks passed ($($records.Count) records)."
