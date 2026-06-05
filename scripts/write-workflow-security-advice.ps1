param(
	[string]$WorkflowRoot = ".github/workflows",
	[string]$ReportPath = "docs/workflow-security-advice.md",
	[string]$JsonPath = "",
	[string]$RecommendedConsumerRef = "v1",
	[switch]$RequireExplicitPermissions,
	[switch]$RequirePinnedActions
)

$ErrorActionPreference = "Stop"

function Resolve-PathForWrite {
	param([string]$Path)

	if ([System.IO.Path]::IsPathRooted($Path)) {
		return $Path
	}
	return Join-Path (Get-Location) $Path
}

function Test-ShaRef {
	param([string]$Ref)

	return $Ref -match '^[A-Fa-f0-9]{40}$'
}

function Get-WorkflowJobs {
	param([string]$Content)

	if ($Content -notmatch '(?ms)^jobs:\s*\r?\n(?<Jobs>.*)$') {
		return @()
	}

	$jobsBlock = $Matches.Jobs
	$jobs = New-Object System.Collections.Generic.List[object]
	foreach ($match in [regex]::Matches($jobsBlock, '(?ms)^\s{2}([A-Za-z0-9_-]+):\s*\r?\n(?<Block>.*?)(?=^\s{2}[A-Za-z0-9_-]+:\s*\r?\n|\z)')) {
		$jobs.Add([pscustomobject]@{
			Name = $match.Groups[1].Value
			Block = $match.Groups["Block"].Value
		})
	}
	return $jobs.ToArray()
}

function Get-ExternalActionRefs {
	param([string]$Content)

	$refs = New-Object System.Collections.Generic.List[object]
	foreach ($match in [regex]::Matches($Content, '(?m)^\s*uses:\s*(?<Uses>[^#\r\n]+?)\s*$')) {
		$uses = $match.Groups["Uses"].Value.Trim().Trim('"').Trim("'")
		if ($uses.StartsWith("./") -or $uses.StartsWith(".\")) {
			continue
		}
		if ($uses -notmatch '@') {
			$refs.Add([pscustomobject]@{
				Uses = $uses
				Ref = ""
				IsPinned = $false
				Issue = "missing-ref"
			})
			continue
		}

		$parts = $uses -split '@', 2
		$ref = $parts[1]
		$isPinned = Test-ShaRef $ref
		$refs.Add([pscustomobject]@{
			Uses = $uses
			Ref = $ref
			IsPinned = $isPinned
			Issue = if ($isPinned) { "" } else { "non-sha-ref" }
		})
	}
	return $refs.ToArray()
}

$workflowRootPath = Resolve-PathForWrite $WorkflowRoot
if (!(Test-Path -LiteralPath $workflowRootPath -PathType Container)) {
	throw "Workflow root was not found: $workflowRootPath"
}

$workflowFiles = @(Get-ChildItem -LiteralPath $workflowRootPath -Filter "*.yml" -File | Sort-Object Name)
if ($workflowFiles.Count -eq 0) {
	throw "No workflow files found in $workflowRootPath"
}

$records = New-Object System.Collections.Generic.List[object]
$missingPermissions = New-Object System.Collections.Generic.List[object]
$unpinnedActions = New-Object System.Collections.Generic.List[object]

foreach ($workflow in $workflowFiles) {
	$content = Get-Content -LiteralPath $workflow.FullName -Raw
	$jobs = @(Get-WorkflowJobs $content)
	$actionRefs = @(Get-ExternalActionRefs $content)
	$workflowMissingPermissions = New-Object System.Collections.Generic.List[string]

	foreach ($job in $jobs) {
		if ($job.Block -notmatch '(?m)^\s{4}permissions:\s*') {
			$workflowMissingPermissions.Add($job.Name)
			$missingPermissions.Add([pscustomobject]@{
				Workflow = $workflow.Name
				Job = $job.Name
			})
		}
	}

	foreach ($actionRef in $actionRefs) {
		if (!$actionRef.IsPinned) {
			$unpinnedActions.Add([pscustomobject]@{
				Workflow = $workflow.Name
				Uses = $actionRef.Uses
				Ref = $actionRef.Ref
				Issue = $actionRef.Issue
			})
		}
	}

	$records.Add([pscustomobject]@{
		workflow = $workflow.Name
		job_count = $jobs.Count
		missing_permissions_jobs = @($workflowMissingPermissions.ToArray())
		external_action_count = $actionRefs.Count
		unpinned_action_count = @($actionRefs | Where-Object { !$_.IsPinned }).Count
	})
}

$summary = [pscustomobject]@{
	workflow_count = $workflowFiles.Count
	job_count = @($records | Measure-Object -Property job_count -Sum).Sum
	missing_permissions_count = $missingPermissions.Count
	unpinned_action_count = $unpinnedActions.Count
	recommended_consumer_ref = $RecommendedConsumerRef
	records = @($records.ToArray())
	missing_permissions = @($missingPermissions.ToArray())
	unpinned_actions = @($unpinnedActions.ToArray())
}

$reportPathResolved = Resolve-PathForWrite $ReportPath
$reportDir = Split-Path -Parent $reportPathResolved
if ($reportDir) {
	New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Workflow Security Advice")
$lines.Add("")
$lines.Add("Advisory guidance and optional enforcement for reusable workflow hardening. Use it before making SHA pinning or least-privilege permissions required.")
$lines.Add("")
$lines.Add("## Summary")
$lines.Add("")
$lines.Add("| Metric | Count |")
$lines.Add("| --- | ---: |")
$lines.Add("| Workflow files | $($summary.workflow_count) |")
$lines.Add("| Jobs | $($summary.job_count) |")
$lines.Add("| Jobs missing explicit permissions | $($summary.missing_permissions_count) |")
$lines.Add("| External actions not pinned to full SHA | $($summary.unpinned_action_count) |")
$lines.Add("")
$lines.Add("Recommended stable consumer ref: ``$RecommendedConsumerRef``.")
$lines.Add("")
$lines.Add("Enforcement: explicit permissions = `$($RequireExplicitPermissions.IsPresent)`; full-SHA action refs = `$($RequirePinnedActions.IsPresent)`.")
$lines.Add("")
$lines.Add("## Missing Job Permissions")
$lines.Add("")
if ($missingPermissions.Count -eq 0) {
	$lines.Add("All jobs declare explicit permissions.")
} else {
	$lines.Add("| Workflow | Job |")
	$lines.Add("| --- | --- |")
	foreach ($entry in $missingPermissions) {
		$lines.Add("| `$($entry.Workflow)` | `$($entry.Job)` |")
	}
}
$lines.Add("")
$lines.Add("## Non-SHA Action References")
$lines.Add("")
if ($unpinnedActions.Count -eq 0) {
	$lines.Add("All external actions are pinned to full commit SHAs.")
} else {
	$lines.Add("| Workflow | Uses | Ref |")
	$lines.Add("| --- | --- | --- |")
	foreach ($entry in $unpinnedActions) {
		$ref = if ([string]::IsNullOrWhiteSpace($entry.Ref)) { "(missing)" } else { $entry.Ref }
		$lines.Add("| `$($entry.Workflow)` | `$($entry.Uses)` | `$ref` |")
	}
}
$lines.Add("")
$lines.Add("## Rollout Notes")
$lines.Add("")
$lines.Add("- Start by adding explicit `permissions: contents: read` to read-only jobs.")
$lines.Add("- Keep tag-based external action refs visible while Dependabot coverage is added.")
$lines.Add("- Promote callers from `@main` to `$RecommendedConsumerRef` after a versioned workflow release is tagged.")

[System.IO.File]::WriteAllText($reportPathResolved, (($lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote workflow security advice: $reportPathResolved"

if (![string]::IsNullOrWhiteSpace($JsonPath)) {
	$jsonPathResolved = Resolve-PathForWrite $JsonPath
	$jsonDir = Split-Path -Parent $jsonPathResolved
	if ($jsonDir) {
		New-Item -ItemType Directory -Force -Path $jsonDir | Out-Null
	}
	$json = $summary | ConvertTo-Json -Depth 8
	[System.IO.File]::WriteAllText($jsonPathResolved, "$json`n", [System.Text.UTF8Encoding]::new($false))
	Write-Host "Wrote workflow security advice JSON: $jsonPathResolved"
}

Write-Host "Workflow security advice: $($summary.missing_permissions_count) missing permissions, $($summary.unpinned_action_count) non-SHA action refs."

$violations = New-Object System.Collections.Generic.List[string]
if ($RequireExplicitPermissions -and $missingPermissions.Count -gt 0) {
	$violations.Add("Explicit job permissions are required, but $($missingPermissions.Count) job(s) are missing permissions.")
}
if ($RequirePinnedActions -and $unpinnedActions.Count -gt 0) {
	$violations.Add("Full-SHA external action refs are required, but $($unpinnedActions.Count) action reference(s) are not pinned.")
}

if ($violations.Count -gt 0) {
	throw ($violations -join " ")
}
