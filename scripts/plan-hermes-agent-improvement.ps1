param(
	[ValidateSet("all", "memory", "evals", "operating-loop", "source-learning", "addon-fanout")]
	[string]$Focus = "all",
	[switch]$PromptQueue,
	[ValidateSet("all", "role-review", "addon-review")]
	[string]$QueueType = "all",
	[string]$QueueId = "",
	[switch]$Json
)

$ErrorActionPreference = "Stop"

function New-AgentRole {
	param(
		[string]$Id,
		[string]$Focus,
		[string]$Specialization,
		[string]$Skill,
		[string]$LaneBoundary,
		[string]$Question,
		[string[]]$ReadFirst,
		[string[]]$Output,
		[string[]]$Evidence,
		[string[]]$StopConditions
	)

	return [ordered]@{
		id = $Id
		focus = $Focus
		specialization = $Specialization
		skill = $Skill
		authority = "reviewer"
		lane_boundary = $LaneBoundary
		mode = "read-only review"
		question = $Question
		read_first = @($ReadFirst)
		output = @($Output)
		output_contract = @($Output)
		evidence = @($Evidence)
		allowed_actions = @(
			"read bounded local files",
			"report findings with severity, file references, validation risk, and suggested owner",
			"run named validation only when explicitly assigned validator work"
		)
		forbidden_actions = @(
			"edit files without a disjoint write scope",
			"commit generated artifacts, model weights, binaries, media dumps, caches, or memory indexes",
			"act as final integrator"
		)
		prompt_packet = [ordered]@{
			title = "$Id prompt packet"
			read_first = @($ReadFirst)
			question = $Question
			output_contract = @($Output)
			stop_conditions = @($StopConditions)
			prompt = "Act as $Id. Specialization: $Specialization. Read only these files: $($ReadFirst -join '; '). Answer exactly this question: $Question. Report findings with severity, file references, validation risk, suggested owner, and accepted/deferred recommendation. Stop if any of these stop conditions apply: $($StopConditions -join '; ')."
			expected_response = @(
				"scope checked",
				"findings with severity and file references",
				"validation risks",
				"accepted or deferred recommendation",
				"stop conditions triggered"
			)
		}
		stop_conditions = @($StopConditions)
	}
}

function New-AddonReviewTarget {
	param(
		[string]$Repo,
		[string]$Lane,
		[string]$AgentId,
		[string]$Specialization,
		[string[]]$ReadFirst,
		[string[]]$FocusQuestions,
		[string]$ValidationCommand,
		[string]$DefaultAction,
		[string]$DirtyPolicy,
		[string[]]$StopConditions
	)

	return [ordered]@{
		repo = $Repo
		lane = $Lane
		agent_id = $AgentId
		specialization = $Specialization
		read_first = @($ReadFirst)
		focus_questions = @($FocusQuestions)
		one_question = $FocusQuestions[0]
		output_shape = @(
			"findings with severity and file references",
			"lane-local risks and validation notes",
			"deferred or out-of-lane items"
		)
		validation_command = $ValidationCommand
		default_action = $DefaultAction
		dirty_policy = $DirtyPolicy
		generated_artifact_policy = "never commit generated project files, binaries, model weights, downloaded runtimes, sample media dumps, memory indexes, or caches"
		handoff_owner = "coordinator/integrator"
		prompt_packet = [ordered]@{
			title = "$AgentId addon review packet"
			read_first = @($ReadFirst)
			question = $FocusQuestions[0]
			output_contract = @(
				"findings with severity and file references",
				"lane-local risks and validation notes",
				"deferred or out-of-lane items"
			)
			stop_conditions = @($StopConditions)
			prompt = "Act as $AgentId for $Repo. Lane: $Lane. Specialization: $Specialization. Read only these lane-local files unless the coordinator expands scope: $($ReadFirst -join '; '). Answer the primary question: $($FocusQuestions[0]). Report findings with severity, file references, lane-local risk, validation notes, and deferred/out-of-lane items. Stop if any of these stop conditions apply: $($StopConditions -join '; '). Do not edit unless the coordinator assigns a clean disjoint write scope."
			expected_response = @(
				"repo and lane checked",
				"primary question answer",
				"findings with severity and file references",
				"dirty or generated-artifact caveats",
				"validation command status or recommendation"
			)
		}
		stop_conditions = @($StopConditions)
	}
}

$roles = @(
	New-AgentRole "memory-reviewer" "memory" "Permanent memory integrity, provenance, and freshness" "memory-contract-auditor" "Workflows memory contract and generated memory readiness only" "Where can Hermes permanent memory become stale, unverifiable, or misleading?" @(
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
		"record ids and source_path values",
		"freshness and tree_state semantics",
		"changed-source and stale-memory checks"
	) @(
		"finding requires generated memory indexes to be committed",
		"finding requires editing companion runtime behavior"
	)

	New-AgentRole "eval-reviewer" "evals" "Prompt-only eval coverage and anti-gaming review" "evaluation-gap-finder" "Hermes prompt-only eval catalog and local catalog tests only" "Which eval scenarios are missing for safe agent-improvement work?" @(
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
		"scenario ids present in markdown and JSON",
		"agent_roles and measurement_signal fields",
		"anti_gaming_failures and required_validations"
	) @(
		"finding widens beyond prompt-only evals",
		"finding cannot be validated locally"
	)

	New-AgentRole "operating-loop-reviewer" "operating-loop" "Delegation flow, integration ownership, and handoff discipline" "operating-loop-contract-reviewer" "Agent operating loop, baseline, skills, and handoff docs only" "How should agents delegate, avoid duplicate work, integrate findings, and report caveats?" @(
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
		"delegation roles and integration owner",
		"accepted and rejected outputs",
		"dirty-state table and validation owner"
	) @(
		"finding requires touching dirty managed repositories",
		"finding assigns final integration to a subagent"
	)

	New-AgentRole "source-learning-reviewer" "source-learning" "Upstream source translation without lane leakage" "source-learning-boundary-reviewer" "Source-learning map, source planner, and openFrameworks/ggml skill docs only" "Where can upstream source learning cause lane confusion or generated artifact risk?" @(
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
		"upstream source ids and local_first paths",
		"translate_to lane mappings",
		"generated artifact stop conditions"
	) @(
		"finding vendors upstream source or artifacts",
		"finding bypasses local instructions"
	)
)

$addonReviewTargets = @(
	New-AddonReviewTarget "ofxGgmlCore" "backend-neutral runtime base" "core-runtime-boundary-agent" "Shared ggml provider, runtime ownership, and ecosystem control-plane review" @("AGENTS.md", "docs/ECOSYSTEM_AGENT.md", "docs/COMPANIONS.md", "docs/RUNTIME_PROVIDER.md") @("Does shared behavior belong in Core?", "Would this create a reverse dependency?", "Is provider evidence backend-neutral?") "..\ofxGgmlCore\scripts\validate-local.ps1" "stop if dirty; coordinator only" "stop when Core is dirty unless the coordinator explicitly accepts the dirty state" @("Core is dirty", "change depends on companion UX")
	New-AddonReviewTarget "ofxGgmlLlama" "text, chat, embeddings" "llama-text-agent" "Text, chat, embedding, and llama.cpp caller workflow review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are model UX and setup scripts companion-owned?", "Does the addon consume Core runtime provider contracts?", "Are text evidence claims reproducible?") "..\ofxGgmlLlama\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding moves chat UX into Core")
	New-AddonReviewTarget "ofxGgmlSam" "segmentation" "sam-segmentation-agent" "Segmentation examples, SAM/SAM2 setup, and visual evidence review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are masks, prompts, and example UX lane-local?", "Is evidence explicit about device and model provenance?", "Are generated media files ignored?") "..\ofxGgmlSam\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding commits sample media dumps")
	New-AddonReviewTarget "ofxGgmlAudio" "audio and speech" "audio-speech-agent" "Audio capture, transcription, and speech evidence review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are audio devices and sample inputs documented as evidence context?", "Are speech model setup scripts companion-owned?", "Are runtime logs openFrameworks-style?") "..\ofxGgmlAudio\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding commits recorded audio")
	New-AddonReviewTarget "ofxGgmlMusic" "music generation and analysis" "music-generation-agent" "MusicGen, AceStep, prompt UX, and audio artifact hygiene review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are model weights and generated songs excluded?", "Are MusicGen/AceStep setup paths lane-local?", "Does evidence separate generation from analysis?") "..\ofxGgmlMusic\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding moves music UX into Core")
	New-AddonReviewTarget "ofxGgmlVision" "image understanding" "vision-understanding-agent" "Image understanding, detector/classifier evidence, and metadata review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are image inputs treated as fixtures or ignored sample data?", "Does evidence identify model/backend context?", "Are metadata promises backed by examples?") "..\ofxGgmlVision\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding commits image dumps")
	New-AddonReviewTarget "ofxGgmlVideo" "video pipelines" "video-pipeline-agent" "Video montage, frame pipeline, and temporal evidence review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are montage features companion-owned?", "Are sample videos and frame dumps ignored?", "Does evidence describe clip, backend, timing, and output provenance?") "..\ofxGgmlVideo\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding commits video/frame dumps")
	New-AddonReviewTarget "ofxGgmlStableDiffusion" "stable-diffusion.cpp image generation" "diffusion-image-agent" "stable-diffusion.cpp setup, image generation UX, and model artifact hygiene review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are stable-diffusion.cpp lessons translated without vendoring?", "Are model weights and generated images excluded?", "Are backend claims backed by smoke evidence?") "..\ofxGgmlStableDiffusion\scripts\validate-local.ps1" "pause fanout if dirty" "pause all fanout when dirty or generated image/model artifacts are present" @("repo is dirty", "finding vendors upstream source")
	New-AddonReviewTarget "ofxGgmlRag" "retrieval and citations" "rag-memory-agent" "RAG retrieval, citation provenance, and memory boundary review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are citations grounded in source paths?", "Is memory treated as generated or refreshable artifact?", "Are retrieval indexes excluded from commits?") "..\ofxGgmlRag\scripts\validate-local.ps1" "pause fanout if dirty" "pause all fanout when dirty or generated retrieval indexes are present" @("repo is dirty", "finding commits retrieval indexes")
	New-AddonReviewTarget "ofxGgmlAgents" "tool-using local agents" "local-agent-tools-agent" "Local tool-agent workflows, permissions, and delegation contract review" @("AGENTS.md", "README.md", "docs/*WORKFLOWS.md", "scripts/validate-local.ps1") @("Are tool permissions explicit?", "Does agent behavior follow Workflows baseline?", "Are local indexes and caches excluded?") "..\ofxGgmlAgents\scripts\validate-local.ps1" "read-only review, edit only when clean" "pause edit fanout when dirty or owner-unknown files are present" @("repo is dirty", "finding weakens permission boundaries")
	New-AddonReviewTarget "ofxGgmlWorkflows" "reusable ecosystem automation" "workflows-coordinator-agent" "Workflow policy, reusable CI contracts, and integration owner" @("AGENTS.md", "README.md", "docs/agent-baseline.md", "docs/agent-handoff-contract.md", "scripts/validate-local.ps1") @("Does the change preserve workflow_call inputs?", "Is validation local and focused?", "Are delegated outputs accepted or rejected explicitly?") "scripts\validate-local.ps1" "coordinator/integration lane" "own integration locally and stop on workflow_call contract breaks without a release plan" @("workflow_call contract breaks without release plan", "finding belongs in companion runtime behavior")
)

$agentSourceReferences = @(
	[ordered]@{
		id = "nousresearch-hermes-agent"
		repo = "NousResearch/hermes-agent"
		url = "https://github.com/NousResearch/hermes-agent"
		use_for = @(
			"learning-loop design",
			"skill creation and self-improvement",
			"persistent searchable memory",
			"isolated subagent fanout"
		)
		translate_to = @(
			"source-grounded memory records",
			"specialized prompt packets",
			"bounded sidecar reviewers",
			"agent-improvement evals"
		)
		do_not_copy = @(
			"do not vendor Hermes Agent code",
			"do not bypass local ofxGgml lane boundaries",
			"do not treat external memory claims as local evidence"
		)
	}
	[ordered]@{
		id = "openai-codex"
		repo = "openai/codex"
		url = "https://github.com/openai/codex"
		use_for = @(
			"local coding-agent ergonomics",
			"repository instruction discovery",
			"terminal-first validation workflow",
			"agent handoff discipline"
		)
		translate_to = @(
			"AGENTS/HERMES instruction layering",
			"local validation before handoff",
			"explicit sandbox and permission prompts",
			"clean final summaries with changed files and tests"
		)
		do_not_copy = @(
			"do not vendor Codex code",
			"do not replace ofxGgml workflow_call contracts",
			"do not weaken generated artifact hygiene"
		)
	}
)

if ($Focus -eq "all" -or $Focus -eq "addon-fanout") {
	$selectedRoles = @($roles)
} else {
	$selectedRoles = @($roles | Where-Object { $_.focus -eq $Focus })
}

$roleLaunchQueue = @(
	foreach ($role in $selectedRoles) {
		[ordered]@{
			type = "role-review"
			id = $role.id
			focus = $role.focus
			specialization = $role.specialization
			launch_mode = "read-only sidecar"
			validation_owner = "coordinator/integrator"
			read_first = @($role.read_first)
			question = $role.question
			output_contract = @($role.output_contract)
			stop_conditions = @($role.stop_conditions)
			prompt_packet = $role.prompt_packet
		}
	}
)

$addonLaunchQueue = @()
if ($Focus -eq "all" -or $Focus -eq "addon-fanout") {
	$addonLaunchQueue = @(
		foreach ($target in $addonReviewTargets) {
			[ordered]@{
				type = "addon-review"
				id = $target.agent_id
				repo = $target.repo
				lane = $target.lane
				specialization = $target.specialization
				launch_mode = $target.default_action
				validation_command = $target.validation_command
				validation_owner = $target.handoff_owner
				read_first = @($target.read_first)
				question = $target.one_question
				output_contract = @($target.output_shape)
				stop_conditions = @($target.stop_conditions)
				prompt_packet = $target.prompt_packet
			}
		}
	)
}

$promptLaunchQueue = @($roleLaunchQueue + $addonLaunchQueue)
if ($QueueType -ne "all") {
	$promptLaunchQueue = @($promptLaunchQueue | Where-Object { $_.type -eq $QueueType })
}
if (![string]::IsNullOrWhiteSpace($QueueId)) {
	$promptLaunchQueue = @($promptLaunchQueue | Where-Object { $_.id -eq $QueueId -or $_.repo -eq $QueueId })
}

$plan = [ordered]@{
	schema_version = 1
	generated_at = [DateTimeOffset]::UtcNow.ToString("o")
	requested_focus = $Focus
	requested_queue_type = $QueueType
	requested_queue_id = $QueueId
	local_first = @(
		"AGENTS.md",
		"HERMES.md",
		"docs/hermes-agent-operating-loop.md",
		"docs/hermes-ecosystem-learning-plan.md",
		"docs/hermes-multi-agent-improvement.md"
	)
	roles = @($selectedRoles)
	addon_review_targets = @($addonReviewTargets)
	agent_source_references = @($agentSourceReferences)
	prompt_launch_queue = @($promptLaunchQueue)
	authority_model = @(
		"coordinator: main agent that classifies the lane and spawns bounded sidecar reviews",
		"retriever: read-only agent that gathers local facts or memory/source-learning context",
		"reviewer: read-only agent that reports findings with severity and validation risk",
		"implementer: optional worker with a disjoint write scope",
		"validator: focused checker that can run tests while implementation continues",
		"integrator: exactly one owner, normally the coordinator"
	)
	thread_spawn_mcp = [ordered]@{
		provider = "ofxGgmlLlamaCodexLocalExample"
		server = "ofxggml_codex_threads"
		tool = "spawn_codex_thread"
		config_block = "[mcp_servers.ofxggml_codex_threads]"
		use_when = @(
			"the MCP server is configured in Codex config",
			"the user explicitly asks for separate threads or sidecar agents",
			"prompt_launch_queue entries should run as actual Codex app-server threads"
		)
		rules = @(
			"spawn one bounded thread per prompt_launch_queue entry only when requested",
			"include the role prompt, cwd, and model override when the coordinator assigns them",
			"wait for thread results before final integration",
			"fall back to single-threaded simulation when the MCP tool is unavailable"
		)
	}
	thread_spawn_fallback = [ordered]@{
		applies_when = @(
			"MCP thread spawning is unavailable",
			"the active runtime is a local model such as ofxGgmlLlamaCodexLocalExample",
			"the coordinator cannot create isolated sidecar agents with the current tool surface"
		)
		mode = "single-threaded simulation"
		rules = @(
			"process prompt_launch_queue entries sequentially in the coordinator thread",
			"preserve each role's read_first scope, one question, output contract, and stop conditions",
			"mark the handoff as simulated and name the missing spawn capability",
			"do not claim independent subagent execution when using the fallback"
		)
		report_fields = @(
			"runtime",
			"spawn_capability",
			"fallback_mode",
			"queue_entries_simulated"
		)
	}
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

if ($PromptQueue -and $Json) {
	ConvertTo-Json -InputObject @($plan.prompt_launch_queue) -Depth 8
} elseif ($Json) {
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
	if ($PromptQueue) {
		Write-Host "Prompt launch queue:"
		foreach ($entry in $plan.prompt_launch_queue) {
			$target = $entry.id
			if ($entry.repo) {
				$target = "$($entry.id) [$($entry.repo)]"
			}
			Write-Host " - $($entry.type): $target ($($entry.launch_mode))"
		}
	}
}
