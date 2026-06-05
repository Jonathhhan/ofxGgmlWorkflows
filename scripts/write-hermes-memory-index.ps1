param(
	[string]$OutputPath = "build\hermes-memory\hermes-memory-index.json",
	[string]$RepoName = "ofxGgmlWorkflows"
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
	return ""
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

function New-MemoryRecord {
	param(
		[string]$Id,
		[string]$SourcePath,
		[string]$Lane,
		[string]$SourceType,
		[string]$Summary,
		[string[]]$RetrievalTags,
		[string]$Freshness
	)

	$sourceFile = Join-Path $repoRoot ($SourcePath -replace '/', '\')
	if (!(Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
		throw "Memory source path does not exist: $SourcePath"
	}
	$sourceItem = Get-Item -LiteralPath $sourceFile
	$sourceHash = (Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLowerInvariant()

	return [ordered]@{
		id = $Id
		source_path = $SourcePath
		source_sha256 = $sourceHash
		source_modified_at = $sourceItem.LastWriteTimeUtc.ToString("o")
		repo = $RepoName
		lane = $Lane
		source_type = $SourceType
		freshness = $Freshness
		summary = $Summary
		retrieval_tags = @($RetrievalTags)
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$generatedAt = [DateTimeOffset]::UtcNow.ToString("o")
$commitSha = Get-GitValue @("rev-parse", "--short=12", "HEAD")
if ([string]::IsNullOrWhiteSpace($commitSha)) {
	$commitSha = "unknown"
}
$treeState = Get-GitTreeState

$records = @(
	New-MemoryRecord "workflows-agents" "AGENTS.md" "Workflows policy" "instruction" "Codex repository rules for ofxGgmlWorkflows, including workflow lane scope, Core planning, generated artifact hygiene, and validation expectations." @("agents", "instructions", "workflow-lane", "validation", "generated-artifacts") $generatedAt
	New-MemoryRecord "workflows-hermes" "HERMES.md" "Workflows policy" "instruction" "Hermes-specific repository context for reusable workflow contracts, agent baseline mirroring, and ecosystem guardrails." @("hermes", "instructions", "workflow-call", "guardrails") $generatedAt
	New-MemoryRecord "agent-baseline" "docs/agent-baseline.md" "Agent guidance" "instruction" "Shared Hermes, Codex, and Copilot baseline for managed ofxGgml ecosystem behavior." @("agent-baseline", "codex", "copilot", "hermes") $generatedAt
	New-MemoryRecord "agent-handoff" "docs/agent-handoff-contract.md" "Planning" "planning" "Cross-repo handoff contract for rollout, evidence promotion, release planning, and companion PR fanout." @("handoff", "planning", "dirty-repo", "rollout") $generatedAt
	New-MemoryRecord "hermes-operating-loop" "docs/hermes-agent-operating-loop.md" "Agent guidance" "planning" "Lane classification, retrieval packets, stop conditions, validation, and handoff output shape for Hermes tasks." @("operating-loop", "retrieval-packets", "stop-conditions", "validation") $generatedAt
	New-MemoryRecord "hermes-learning-plan" "docs/hermes-ecosystem-learning-plan.md" "Agent guidance" "instruction" "Instruction, RAG and memory, skill, and evaluation layers for training Hermes without changing model weights." @("learning-plan", "rag-memory", "skills", "evals") $generatedAt
	New-MemoryRecord "multi-agent-improvement" "docs/hermes-multi-agent-improvement.md" "Agent guidance" "planning" "Delegation roles, integration owner, anti-duplication, dirty-state table, and output shape for agents improving agents." @("multi-agent", "agent-improvement", "delegation-roles", "integration-owner", "dirty-state-table") $generatedAt
	New-MemoryRecord "source-learning-map" "docs/hermes-source-learning-map.md" "Agent guidance" "runtime" "Source-learning map for upstream ggml-org, stable-diffusion.cpp, and openFrameworks code without crossing ofxGgml Core and companion boundaries." @("ggml-org", "ggml", "llama.cpp", "whisper.cpp", "stable-diffusion.cpp", "openFrameworks", "source-learning") $generatedAt
	New-MemoryRecord "source-learning-planner" "scripts/plan-hermes-source-learning.ps1" "Agent guidance" "planning" "Machine-readable source-learning retrieval packet for upstream openFrameworks, ggml, llama.cpp, whisper.cpp, and stable-diffusion.cpp lanes." @("source-learning", "retrieval-packet", "openFrameworks", "stable-diffusion.cpp", "ggml-org") $generatedAt
	New-MemoryRecord "hermes-skills" "docs/hermes-openframeworks-ggml-skills.md" "Agent guidance" "runtime" "openFrameworks addon loop, ggml runtime ownership, evidence expectations, logging conventions, and generated artifact hygiene." @("openframeworks", "ggml", "core-provider", "artifact-hygiene") $generatedAt
	New-MemoryRecord "hermes-evals" "docs/hermes-openframeworks-ggml-evals.md" "Agent guidance" "validation" "Prompt-only evaluation pack for boundary correctness, retrieval-grounded citations, evidence honesty, and validation behavior." @("evals", "safety", "boundary", "retrieval") $generatedAt
	New-MemoryRecord "hermes-memory-contract" "docs/hermes-memory-contract.md" "Agent guidance" "memory" "Permanent memory contract for source-grounded index records, freshness checks, stale-memory stop conditions, and generated index hygiene." @("memory-contract", "schema_version", "commit_sha", "freshness", "retrieval_tags") $generatedAt
	New-MemoryRecord "evidence-schema-docs" "docs/evidence-schema-v1.md" "Evidence" "evidence" "Evidence Schema v1 ownership, required fields, backend/runtime context, tree state, artifact integrity, and validation contract." @("evidence-schema", "artifact-integrity", "runtime-evidence", "release-gate") $generatedAt
	New-MemoryRecord "workflow-adoption" "docs/workflow-adoption.md" "Workflows policy" "workflow" "Reusable workflow adoption tiers, caller patterns, Core coordination notes, and promotion path." @("workflow-adoption", "workflow_call", "profiles", "rollout") $generatedAt
	New-MemoryRecord "workflow-release-policy" "docs/workflow-release-policy.md" "Release" "release" "Ref policy for main, v1, immutable patch tags, Dependabot coverage, SHA pinning, and validation expectations." @("release-policy", "dependabot", "sha-pinning", "v1") $generatedAt
	New-MemoryRecord "workflow-security-advice" ".github/workflows/workflow-security-advice.yml" "Security" "security" "Report-only workflow hardening contract for explicit permissions, action pinning readiness, and artifact digest output." @("workflow-security", "permissions", "pinned-actions", "artifact_digest") $generatedAt
	New-MemoryRecord "security-advisor-script" "scripts/write-workflow-security-advice.ps1" "Security" "security" "PowerShell generator that reports missing permissions, unpinned external actions, recommended consumer refs, and hardening advice." @("workflow-security", "security-advice", "report-generator") $generatedAt
	New-MemoryRecord "local-validation" "scripts/validate-local.ps1" "Validation" "validation" "Local validation entrypoint for manifest inventory, workflow syntax, evidence tests, workflow fixtures, Hermes memory, evals, and metadata extraction." @("validation", "validate-local", "manifest", "hermes-memory") $generatedAt
)

foreach ($record in $records) {
	$source = Join-Path $repoRoot ($record.source_path -replace '/', '\')
	if (!(Test-Path -LiteralPath $source -PathType Leaf)) {
		throw "Memory source path does not exist: $($record.source_path)"
	}
}

$index = [ordered]@{
	schema_version = 1
	generated_at = $generatedAt
	repo = $RepoName
	commit_sha = $commitSha
	tree_state = $treeState
	records = @($records)
}

$resolvedOutputPath = $OutputPath
if (![System.IO.Path]::IsPathRooted($resolvedOutputPath)) {
	$resolvedOutputPath = Join-Path $repoRoot $resolvedOutputPath
}
$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (!(Test-Path -LiteralPath $outputDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$json = $index | ConvertTo-Json -Depth 8
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($resolvedOutputPath, $json + [Environment]::NewLine, $utf8NoBom)
Write-Host "Wrote Hermes memory index: $resolvedOutputPath"
