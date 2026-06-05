$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$plannerPath = Join-Path $repoRoot "scripts\plan-hermes-agent-improvement.ps1"

if (!(Test-Path -LiteralPath $plannerPath -PathType Leaf)) {
	throw "Hermes agent-improvement planner was not found: $plannerPath"
}

$plan = (& $plannerPath -Json) | ConvertFrom-Json
if ([int]$plan.schema_version -ne 1) {
	throw "Hermes agent-improvement plan schema_version must be 1."
}
if ([string]$plan.requested_focus -ne "all") {
	throw "Hermes agent-improvement default focus should be all."
}

foreach ($path in @("AGENTS.md", "HERMES.md", "docs/hermes-agent-operating-loop.md", "docs/hermes-multi-agent-improvement.md")) {
	if ($path -notin @($plan.local_first)) {
		throw "Hermes agent-improvement local_first is missing: $path"
	}
}

$roles = @($plan.roles)
if ($roles.Count -ne 4) {
	throw "Hermes agent-improvement plan should include 4 review roles."
}

$roleIds = @($roles | Select-Object -ExpandProperty id)
foreach ($requiredRole in @("memory-reviewer", "eval-reviewer", "operating-loop-reviewer", "source-learning-reviewer")) {
	if ($requiredRole -notin $roleIds) {
		throw "Hermes agent-improvement plan is missing role: $requiredRole"
	}
}

foreach ($role in $roles) {
	if ([string]$role.mode -ne "read-only review") {
		throw "Hermes agent-improvement role $($role.id) should default to read-only review."
	}
	if ([string]$role.authority -ne "reviewer") {
		throw "Hermes agent-improvement role $($role.id) should have reviewer authority."
	}
	if ([string]::IsNullOrWhiteSpace([string]$role.specialization)) {
		throw "Hermes agent-improvement role $($role.id) must include a specialization."
	}
	if ([string]::IsNullOrWhiteSpace([string]$role.skill)) {
		throw "Hermes agent-improvement role $($role.id) must include a specialized skill."
	}
	if ([string]::IsNullOrWhiteSpace([string]$role.lane_boundary)) {
		throw "Hermes agent-improvement role $($role.id) must include a lane boundary."
	}
	if (@($role.read_first).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) must include read_first files."
	}
	if (@($role.output).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) must include output expectations."
	}
	if (@($role.output_contract).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) must include an output contract."
	}
	if (@($role.evidence).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) must include evidence expectations."
	}
	foreach ($property in @("allowed_actions", "forbidden_actions")) {
		if (@($role.$property).Count -eq 0) {
			throw "Hermes agent-improvement role $($role.id) must include $property."
		}
	}
	if (@($role.stop_conditions).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) must include stop conditions."
	}
}

foreach ($ruleToken in @("main agent owns edits", "do not duplicate", "deferred findings")) {
	if (@($plan.integration_rules | Where-Object { $_ -match [regex]::Escape($ruleToken) }).Count -eq 0) {
		throw "Hermes agent-improvement integration rules should mention: $ruleToken"
	}
}

foreach ($authorityToken in @("coordinator", "retriever", "reviewer", "integrator")) {
	if (@($plan.authority_model | Where-Object { $_ -match [regex]::Escape($authorityToken) }).Count -eq 0) {
		throw "Hermes agent-improvement authority model should mention: $authorityToken"
	}
}

foreach ($column in @("repository", "files_or_count", "relevance", "owner", "generated_artifact", "action")) {
	if ($column -notin @($plan.dirty_state_table_columns)) {
		throw "Hermes agent-improvement dirty-state table columns should include: $column"
	}
}

if (@($plan.addon_review_targets).Count -lt 10) {
	throw "Hermes agent-improvement plan should include managed addon review targets."
}
foreach ($repo in @("ofxGgmlCore", "ofxGgmlStableDiffusion", "ofxGgmlRag", "ofxGgmlWorkflows")) {
	if ($repo -notin @($plan.addon_review_targets | Select-Object -ExpandProperty repo)) {
		throw "Hermes agent-improvement addon review targets should include: $repo"
	}
}
foreach ($target in @($plan.addon_review_targets)) {
	foreach ($property in @("agent_id", "specialization", "read_first", "focus_questions", "one_question", "output_shape", "validation_command", "dirty_policy", "generated_artifact_policy", "handoff_owner", "stop_conditions")) {
		if ($null -eq $target.$property) {
			throw "Hermes agent-improvement addon target $($target.repo) is missing $property."
		}
	}
	if (@($target.focus_questions).Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$target.one_question)) {
		throw "Hermes agent-improvement addon target $($target.repo) must include a lane-specific question."
	}
	if ([string]$target.handoff_owner -ne "coordinator/integrator") {
		throw "Hermes agent-improvement addon target $($target.repo) should keep handoff owner as coordinator/integrator."
	}
}
foreach ($ruleToken in @("one agent per addon", "clean target repos", "pauses fanout")) {
	if (@($plan.addon_fanout_rules | Where-Object { $_ -match [regex]::Escape($ruleToken) }).Count -eq 0) {
		throw "Hermes agent-improvement addon fanout rules should mention: $ruleToken"
	}
}

$memoryPlan = (& $plannerPath -Focus memory -Json) | ConvertFrom-Json
if (@($memoryPlan.roles).Count -ne 1 -or [string]$memoryPlan.roles[0].id -ne "memory-reviewer") {
	throw "Hermes agent-improvement memory focus should select only memory-reviewer."
}

$fanoutPlan = (& $plannerPath -Focus addon-fanout -Json) | ConvertFrom-Json
if (@($fanoutPlan.addon_review_targets).Count -lt 10) {
	throw "Hermes agent-improvement addon-fanout focus should include addon review targets."
}

Write-Host "Hermes agent-improvement plan checks passed."
