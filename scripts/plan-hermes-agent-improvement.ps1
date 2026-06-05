param(
	[ValidateSet("all", "memory", "evals", "operating-loop", "source-learning", "addon-fanout")]
	[string]$Focus = "all",
	[switch]$Json
)

$ErrorActionPreference = "Stop"

function New-AgentRole {
	param(
		[string]$Id,
		[string]$Focus,
		[string]$Question,
		[string[]]$ReadFirst,
		[string[]]$Output,
		[string[]]$StopConditions
	)

	return [ordered]@{
		id = $Id
		focus = $Focus
		mode = "read-only review"
		question = $Question
		read_first = @($ReadFirst)
		output = @($Output)
		stop_conditions = @($StopConditions)
	}
}

$roles = @(
	New-AgentRole "memory-reviewer" "memory" "Where can Hermes permanent memory become stale, unverifiable, or misleading?" @(
		"docs/hermes-memory-contract.md",
		"schemas/hermes-memory-v1.schema.json",
		"scripts/write-hermes-memory-index.ps1",
		"scripts/check-hermes-memory-index.ps1",
		"scripts/test-hermes-memory-index.ps1",
		"scripts/test-hermes-memory-readiness.ps1"
	) @(
		"source provenance gaps",
		"stale-memory stop-condition gaps",
		"readiness report improvements",
		"validation additions"
	) @(
		"finding requires generated memory indexes to be committed",
		"finding requires editing companion runtime behavior"
	)

	New-AgentRole "eval-reviewer" "evals" "Which eval scenarios are missing for safe agent-improvement work?" @(
		"docs/hermes-openframeworks-ggml-evals.md",
		"docs/hermes-openframeworks-ggml-evals.json",
		"scripts/test-hermes-eval-catalog.ps1",
		"docs/hermes-ecosystem-learning-plan.md"
	) @(
		"missing scenario ids and titles",
		"unsafe failure examples",
		"scoring or validation gaps",
		"readiness thresholds"
	) @(
		"finding widens beyond prompt-only evals",
		"finding cannot be validated locally"
	)

	New-AgentRole "operating-loop-reviewer" "operating-loop" "How should agents delegate, avoid duplicate work, integrate findings, and report caveats?" @(
		"docs/hermes-agent-operating-loop.md",
		"docs/hermes-ecosystem-learning-plan.md",
		"docs/hermes-openframeworks-ggml-skills.md",
		"docs/agent-handoff-contract.md",
		"docs/agent-baseline.md"
	) @(
		"delegation gaps",
		"anti-duplication gaps",
		"integration ownership gaps",
		"dirty-repo and validation gaps"
	) @(
		"finding requires touching dirty managed repositories",
		"finding assigns final integration to a subagent"
	)

	New-AgentRole "source-learning-reviewer" "source-learning" "Where can upstream source learning cause lane confusion or generated artifact risk?" @(
		"docs/hermes-source-learning-map.md",
		"scripts/plan-hermes-source-learning.ps1",
		"scripts/test-hermes-source-learning-plan.ps1",
		"docs/hermes-openframeworks-ggml-skills.md"
	) @(
		"upstream-source coverage gaps",
		"Core versus companion lane risks",
		"generated artifact risks",
		"retrieval packet improvements"
	) @(
		"finding vendors upstream source or artifacts",
		"finding bypasses local instructions"
	)
)

$addonReviewTargets = @(
	[ordered]@{ repo = "ofxGgmlCore"; lane = "backend-neutral runtime base"; default_action = "stop if dirty; coordinator only" }
	[ordered]@{ repo = "ofxGgmlLlama"; lane = "text, chat, embeddings"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlSam"; lane = "segmentation"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlAudio"; lane = "audio and speech"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlMusic"; lane = "music generation and analysis"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlVision"; lane = "image understanding"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlVideo"; lane = "video pipelines"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlStableDiffusion"; lane = "stable-diffusion.cpp image generation"; default_action = "pause fanout if dirty" }
	[ordered]@{ repo = "ofxGgmlRag"; lane = "retrieval and citations"; default_action = "pause fanout if dirty" }
	[ordered]@{ repo = "ofxGgmlAgents"; lane = "tool-using local agents"; default_action = "read-only review, edit only when clean" }
	[ordered]@{ repo = "ofxGgmlWorkflows"; lane = "reusable ecosystem automation"; default_action = "coordinator/integration lane" }
)

if ($Focus -eq "all" -or $Focus -eq "addon-fanout") {
	$selectedRoles = @($roles)
} else {
	$selectedRoles = @($roles | Where-Object { $_.focus -eq $Focus })
}

$plan = [ordered]@{
	schema_version = 1
	generated_at = [DateTimeOffset]::UtcNow.ToString("o")
	requested_focus = $Focus
	local_first = @(
		"AGENTS.md",
		"HERMES.md",
		"docs/hermes-agent-operating-loop.md",
		"docs/hermes-ecosystem-learning-plan.md",
		"docs/hermes-multi-agent-improvement.md"
	)
	roles = @($selectedRoles)
	addon_review_targets = @($addonReviewTargets)
	authority_model = @(
		"coordinator: main agent that classifies the lane and spawns bounded sidecar reviews",
		"retriever: read-only agent that gathers local facts or memory/source-learning context",
		"reviewer: read-only agent that reports findings with severity and validation risk",
		"implementer: optional worker with a disjoint write scope",
		"validator: focused checker that can run tests while implementation continues",
		"integrator: exactly one owner, normally the coordinator"
	)
	dirty_state_table_columns = @(
		"repository",
		"files_or_count",
		"relevance",
		"owner",
		"generated_artifact",
		"action"
	)
	integration_rules = @(
		"main agent owns edits, validation, commit scope, and final handoff",
		"subagents are read-only unless assigned disjoint write scopes",
		"do not duplicate questions or write scopes across agents",
		"search canonical docs, scripts, schemas, and workflow inputs before adding artifacts",
		"integrate only findings inside the current lane or handoff",
		"report useful deferred findings without widening the change"
	)
	addon_fanout_rules = @(
		"one agent per addon is for read-only review or advisory planning by default",
		"edit fanout requires clean target repos or explicit dirty-state acceptance",
		"each addon agent must have a disjoint repository and write scope",
		"coordinator pauses fanout for dirty, owner-unknown, or generated-artifact changes"
	)
	validation = @(
		"scripts/test-hermes-agent-improvement-plan.ps1",
		"scripts/validate-local.ps1"
	)
}

if ($Json) {
	$plan | ConvertTo-Json -Depth 8
} else {
	Write-Host "Hermes agent-improvement plan: $Focus"
	Write-Host "Local files first:"
	foreach ($path in $plan.local_first) {
		Write-Host " - $path"
	}
	Write-Host "Agent roles:"
	foreach ($role in $plan.roles) {
		Write-Host " - $($role.id): $($role.question)"
	}
	Write-Host "Authority model:"
	foreach ($authority in $plan.authority_model) {
		Write-Host " - $authority"
	}
	Write-Host "Integration rules:"
	foreach ($rule in $plan.integration_rules) {
		Write-Host " - $rule"
	}
	if ($Focus -eq "addon-fanout") {
		Write-Host "Addon review targets:"
		foreach ($target in $plan.addon_review_targets) {
			Write-Host " - $($target.repo): $($target.default_action)"
		}
	}
}
