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
	if ($null -eq $role.prompt_packet) {
		throw "Hermes agent-improvement role $($role.id) must include a prompt packet."
	}
	if ([string]::IsNullOrWhiteSpace([string]$role.prompt_packet.prompt) -or @($role.prompt_packet.expected_response).Count -eq 0) {
		throw "Hermes agent-improvement role $($role.id) prompt packet must include prompt and expected_response."
	}
	if ([string]$role.prompt_packet.prompt -notmatch [regex]::Escape([string]$role.id)) {
		throw "Hermes agent-improvement role $($role.id) prompt packet should name the role."
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
	foreach ($property in @("agent_id", "specialization", "read_first", "focus_questions", "one_question", "output_shape", "validation_command", "dirty_policy", "generated_artifact_policy", "handoff_owner", "prompt_packet", "stop_conditions")) {
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
	if ([string]::IsNullOrWhiteSpace([string]$target.prompt_packet.prompt) -or @($target.prompt_packet.expected_response).Count -eq 0) {
		throw "Hermes agent-improvement addon target $($target.repo) prompt packet must include prompt and expected_response."
	}
	if ([string]$target.prompt_packet.prompt -notmatch [regex]::Escape([string]$target.agent_id)) {
		throw "Hermes agent-improvement addon target $($target.repo) prompt packet should name the addon agent."
	}
}
foreach ($ruleToken in @("one agent per addon", "clean target repos", "pauses fanout")) {
	if (@($plan.addon_fanout_rules | Where-Object { $_ -match [regex]::Escape($ruleToken) }).Count -eq 0) {
		throw "Hermes agent-improvement addon fanout rules should mention: $ruleToken"
	}
}

$sourceReferences = @($plan.agent_source_references)
if ($sourceReferences.Count -lt 2) {
	throw "Hermes agent-improvement plan should include agent source-learning references."
}
foreach ($sourceId in @("nousresearch-hermes-agent", "openai-codex")) {
	$source = @($sourceReferences | Where-Object { $_.id -eq $sourceId })[0]
	if ($null -eq $source) {
		throw "Hermes agent-improvement plan is missing source reference: $sourceId"
	}
	foreach ($property in @("repo", "url", "use_for", "translate_to", "do_not_copy")) {
		if ($null -eq $source.$property) {
			throw "Hermes agent-improvement source reference $sourceId is missing $property."
		}
	}
	if (@($source.do_not_copy | Where-Object { $_ -match "do not vendor" }).Count -eq 0) {
		throw "Hermes agent-improvement source reference $sourceId should forbid vendoring source code."
	}
}

$launchQueue = @($plan.prompt_launch_queue)
if ($launchQueue.Count -ne (@($plan.roles).Count + @($plan.addon_review_targets).Count)) {
	throw "Hermes agent-improvement default prompt launch queue should include selected roles and addon targets."
}
foreach ($entry in $launchQueue) {
	foreach ($property in @("type", "id", "specialization", "launch_mode", "validation_owner", "prompt_packet")) {
		if ($null -eq $entry.$property) {
			throw "Hermes agent-improvement prompt launch queue entry is missing $property."
		}
	}
	if ([string]::IsNullOrWhiteSpace([string]$entry.prompt_packet.prompt)) {
		throw "Hermes agent-improvement prompt launch queue entry $($entry.id) must include prompt text."
	}
}

$memoryPlan = (& $plannerPath -Focus memory -Json) | ConvertFrom-Json
if (@($memoryPlan.roles).Count -ne 1 -or [string]$memoryPlan.roles[0].id -ne "memory-reviewer") {
	throw "Hermes agent-improvement memory focus should select only memory-reviewer."
}
if (@($memoryPlan.prompt_launch_queue).Count -ne 1 -or [string]$memoryPlan.prompt_launch_queue[0].id -ne "memory-reviewer") {
	throw "Hermes agent-improvement memory focus should expose one role prompt launch queue entry."
}
$memoryQueue = (& $plannerPath -Focus memory -PromptQueue -Json) | ConvertFrom-Json
if (@($memoryQueue).Count -ne 1 -or [string]$memoryQueue[0].id -ne "memory-reviewer") {
	throw "Hermes agent-improvement memory prompt queue output should include only memory-reviewer."
}

$fanoutPlan = (& $plannerPath -Focus addon-fanout -Json) | ConvertFrom-Json
if (@($fanoutPlan.addon_review_targets).Count -lt 10) {
	throw "Hermes agent-improvement addon-fanout focus should include addon review targets."
}
if (@($fanoutPlan.prompt_launch_queue | Where-Object { $_.type -eq "addon-review" }).Count -ne @($fanoutPlan.addon_review_targets).Count) {
	throw "Hermes agent-improvement addon-fanout prompt launch queue should include each addon target."
}
$fanoutQueue = (& $plannerPath -Focus addon-fanout -PromptQueue -Json) | ConvertFrom-Json
if (@($fanoutQueue | Where-Object { $_.type -eq "addon-review" }).Count -ne @($fanoutPlan.addon_review_targets).Count) {
	throw "Hermes agent-improvement addon-fanout prompt queue output should include each addon target."
}
foreach ($queueEntry in @($fanoutQueue)) {
	if ($null -eq $queueEntry.prompt_packet -or [string]::IsNullOrWhiteSpace([string]$queueEntry.prompt_packet.prompt)) {
		throw "Hermes agent-improvement prompt queue output entry $($queueEntry.id) should include prompt text."
	}
}

$roleOnlyQueue = (& $plannerPath -Focus addon-fanout -PromptQueue -QueueType role-review -Json) | ConvertFrom-Json
if (@($roleOnlyQueue).Count -ne @($fanoutPlan.roles).Count) {
	throw "Hermes agent-improvement role-review queue selector should include selected roles only."
}
if (@($roleOnlyQueue | Where-Object { $_.type -ne "role-review" }).Count -ne 0) {
	throw "Hermes agent-improvement role-review queue selector should not include addon reviews."
}

$addonOnlyQueue = (& $plannerPath -Focus addon-fanout -PromptQueue -QueueType addon-review -Json) | ConvertFrom-Json
if (@($addonOnlyQueue).Count -ne @($fanoutPlan.addon_review_targets).Count) {
	throw "Hermes agent-improvement addon-review queue selector should include addon targets only."
}
if (@($addonOnlyQueue | Where-Object { $_.type -ne "addon-review" }).Count -ne 0) {
	throw "Hermes agent-improvement addon-review queue selector should not include role reviews."
}

$ragQueue = (& $plannerPath -Focus addon-fanout -PromptQueue -QueueId rag-memory-agent -Json) | ConvertFrom-Json
if (@($ragQueue).Count -ne 1 -or [string]$ragQueue[0].repo -ne "ofxGgmlRag") {
	throw "Hermes agent-improvement QueueId should select rag-memory-agent."
}

$repoQueue = (& $plannerPath -Focus addon-fanout -PromptQueue -QueueId ofxGgmlVideo -Json) | ConvertFrom-Json
if (@($repoQueue).Count -ne 1 -or [string]$repoQueue[0].id -ne "video-pipeline-agent") {
	throw "Hermes agent-improvement QueueId should select addon queue entries by repo name."
}

$emptyQueue = (& $plannerPath -Focus memory -PromptQueue -QueueType addon-review -Json) | ConvertFrom-Json
if (@($emptyQueue).Count -ne 0) {
	throw "Hermes agent-improvement queue selectors should allow empty queue results."
}

Write-Host "Hermes agent-improvement plan checks passed."
