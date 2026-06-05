param(
	[ValidateSet("all", "addon-layout", "core-runtime", "text-inference", "audio-speech", "diffusion-image-video")]
	[string]$Lane = "all",
	[switch]$Json
)

$ErrorActionPreference = "Stop"

function New-Source {
	param(
		[string]$Id,
		[string]$Lane,
		[string]$Name,
		[string]$Url,
		[string[]]$ReadFirst,
		[string[]]$Learn,
		[string]$TranslateTo
	)

	return [ordered]@{
		id = $Id
		lane = $Lane
		name = $Name
		url = $Url
		read_first = @($ReadFirst)
		learn = @($Learn)
		translate_to = $TranslateTo
	}
}

$sources = @(
	New-Source "openframeworks" "addon-layout" "openFrameworks" "https://github.com/openframeworks/openFrameworks" @(
		"addons",
		"apps",
		"docs",
		"examples",
		"libs",
		"scripts",
		"projectGenerator",
		"platform docs"
	) @(
		"C++ creative-coding toolkit layout",
		"self-contained release structure",
		"addon and example folder conventions",
		"projectGenerator-produced files are disposable"
	) "companion UX or Workflows addon hygiene"

	New-Source "ggml" "core-runtime" "ggml" "https://github.com/ggml-org/ggml" @(
		"include",
		"src",
		"tests",
		"examples",
		"docs",
		"CMake files"
	) @(
		"tensor and backend provider contracts",
		"quantization and GGUF-related primitives",
		"cross-platform runtime patterns",
		"no-runtime-allocation expectations"
	) "Core runtime"

	New-Source "llama-cpp" "text-inference" "llama.cpp" "https://github.com/ggml-org/llama.cpp" @(
		"docs",
		"model loading code",
		"GGUF paths",
		"backend integration",
		"server and tools",
		"API changelogs"
	) @(
		"LLM inference provider behavior",
		"model loading and GGUF metadata handling",
		"backend and server contract changes",
		"tool-facing API stability risks"
	) "Core runtime or Llama companion UX"

	New-Source "whisper-cpp" "audio-speech" "whisper.cpp" "https://github.com/ggml-org/whisper.cpp" @(
		"whisper.h",
		"whisper.cpp",
		"examples",
		"models scripts",
		"quantization paths",
		"backend setup docs"
	) @(
		"speech model API shape",
		"audio example and model setup patterns",
		"quantized model handling",
		"backend-specific setup caveats"
	) "Core runtime or Audio companion UX"

	New-Source "stable-diffusion-cpp" "diffusion-image-video" "stable-diffusion.cpp" "https://github.com/leejet/stable-diffusion.cpp" @(
		"include",
		"src",
		"examples",
		"docs",
		"CMake files",
		"backend selection",
		"performance guide",
		"quantization and GGUF docs",
		"CLI docs"
	) @(
		"diffusion model loading and conversion",
		"sampler and scheduler behavior",
		"image, edit, and video generation paths",
		"backend placement and memory tradeoffs"
	) "StableDiffusion or Video companion UX"
)

if ($Lane -eq "all") {
	$selectedSources = @($sources)
} else {
	$selectedSources = @($sources | Where-Object { $_.lane -eq $Lane })
}

$plan = [ordered]@{
	schema_version = 1
	generated_at = [DateTimeOffset]::UtcNow.ToString("o")
	requested_lane = $Lane
	local_first = @(
		"AGENTS.md",
		"HERMES.md",
		"docs/hermes-source-learning-map.md",
		"docs/hermes-memory-contract.md",
		"docs/hermes-openframeworks-ggml-skills.md",
		"docs/hermes-agent-operating-loop.md"
	)
	sources = @($selectedSources)
	stop_conditions = @(
		"upstream lesson implies changing Core and a companion addon together",
		"change would vendor upstream generated artifacts, model files, binaries, caches, or sample media",
		"upstream API, command-line option, backend behavior, or openFrameworks release layout changed recently and local docs have not been refreshed",
		"runtime support cannot be proven with local smoke or evidence scripts"
	)
	output_shape = @(
		"source URLs and folders inspected",
		"local files retrieved first",
		"lane decision: Core runtime, Workflows policy, or companion UX",
		"stop conditions and generated artifact risks",
		"validation command to run before handoff"
	)
}

if ($Json) {
	$plan | ConvertTo-Json -Depth 8
} else {
	Write-Host "Hermes source-learning plan: $Lane"
	Write-Host "Local files first:"
	foreach ($path in $plan.local_first) {
		Write-Host " - $path"
	}
	Write-Host "Upstream sources:"
	foreach ($source in $plan.sources) {
		Write-Host " - $($source.name): $($source.url)"
		Write-Host "   read: $($source.read_first -join ', ')"
		Write-Host "   translate to: $($source.translate_to)"
	}
	Write-Host "Stop conditions:"
	foreach ($condition in $plan.stop_conditions) {
		Write-Host " - $condition"
	}
}
