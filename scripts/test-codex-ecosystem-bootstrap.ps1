param()

$ErrorActionPreference = "Stop"

function Assert-Contains {
	param(
		[string]$Content,
		[string]$Expected,
		[string]$Label
	)

	if (!$Content.Contains($Expected)) {
		throw "$Label is missing required bootstrap text: $Expected"
	}
}

function Assert-Before {
	param(
		[string]$Content,
		[string]$Earlier,
		[string]$Later,
		[string]$Label
	)

	$earlierIndex = $Content.IndexOf($Earlier, [StringComparison]::Ordinal)
	$laterIndex = $Content.IndexOf($Later, [StringComparison]::Ordinal)
	if ($earlierIndex -lt 0 -or $laterIndex -lt 0 -or $earlierIndex -ge $laterIndex) {
		throw "$Label does not place '$Earlier' before '$Later'."
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$agentsPath = Join-Path $repoRoot "AGENTS.md"
$ecosystemPath = Join-Path $repoRoot "ecosystem.yaml"
$recursiveSkillPath = Join-Path $repoRoot ".agents\skills\recursive-codex\SKILL.md"
$capabilitySkillPath = Join-Path $repoRoot ".agents\skills\ofxggml-capability-loop\SKILL.md"
$usagePath = Join-Path $repoRoot "docs\codex-ecosystem-usage.md"

foreach ($requiredPath in @(
	$agentsPath,
	$ecosystemPath,
	$recursiveSkillPath,
	$capabilitySkillPath,
	$usagePath
)) {
	if (!(Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
		throw "Fresh-checkout bootstrap dependency is missing: $requiredPath"
	}
}

$agents = Get-Content -LiteralPath $agentsPath -Raw
$recursiveSkill = Get-Content -LiteralPath $recursiveSkillPath -Raw
$capabilitySkill = Get-Content -LiteralPath $capabilitySkillPath -Raw
$usage = Get-Content -LiteralPath $usagePath -Raw
$ecosystem = Get-Content -LiteralPath $ecosystemPath -Raw

# Simulate the instruction discovery for: "Improve the entire ofxGgml ecosystem."
# This checks the deterministic fresh-checkout contract; it does not claim that
# a model-backed Codex task was exercised.
Assert-Before $agents 'Read `ecosystem.yaml` before proposing changes' 'Load the repository-local `$recursive-codex`' "AGENTS.md"
Assert-Before $agents 'Load the repository-local `$recursive-codex`' 'observable capability' "AGENTS.md"
Assert-Before $agents 'observable capability' 'first demonstrated blocker' "AGENTS.md"
Assert-Before $agents 'first demonstrated blocker' 'smallest necessary change' "AGENTS.md"
Assert-Before $agents 'smallest necessary change' 'claim-matched evidence' "AGENTS.md"
Assert-Contains $agents 'Speculative preparation requires explicit user' "AGENTS.md"
Assert-Contains $agents 'introduce speculative public APIs without the' "AGENTS.md"
Assert-Contains $agents 'Treat `proof` values in `ecosystem.yaml` as claim identifiers' "AGENTS.md"
Assert-Contains $agents '`verification_required`' "AGENTS.md"

$unverifiedClaims = [regex]::Matches($ecosystem, '(?m)^\s*status:\s*verification_required\s*$').Count
if ($unverifiedClaims -ne 11) {
	throw "ecosystem.yaml must contain 11 verification_required claims until current evidence is linked; found $unverifiedClaims."
}
if ($ecosystem -match '(?m)^\s*status:\s*proven\s*$') {
	throw "ecosystem.yaml contains an unlinked proven status."
}

Assert-Contains $recursiveSkill 'user goal' "repository-local recursive-codex skill"
Assert-Contains $recursiveSkill 'observable capability or effect' "repository-local recursive-codex skill"
Assert-Contains $recursiveSkill 'first demonstrated blocker' "repository-local recursive-codex skill"
Assert-Contains $recursiveSkill 'Classify evidence by kind and claim' "repository-local recursive-codex skill"
Assert-Contains $recursiveSkill 'Recur on the decision' "repository-local recursive-codex skill"
if ($recursiveSkill.Contains('[TODO')) {
	throw "repository-local recursive-codex skill still contains scaffold TODOs."
}

Assert-Contains $capabilitySkill '../recursive-codex/SKILL.md' "ofxGgml capability skill"
Assert-Contains $capabilitySkill 'do not assume a' "ofxGgml capability skill"
Assert-Contains $usage 'ofxGgmlAgents` is intentionally runtime-link independent' "ecosystem usage guide"
Assert-Contains $usage 'first demonstrated blocker' "ecosystem usage guide"
Assert-Contains $usage 'Do not begin by inventing a workflow' "ecosystem usage guide"
Assert-Contains $usage 'stable claim identifiers, not proof' "ecosystem usage guide"
Assert-Contains $usage 'remains `verification_required`' "ecosystem usage guide"

Write-Host "Codex ecosystem bootstrap contract passed (deterministic inspection)."
