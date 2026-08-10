param(
	[Parameter(Mandatory = $true)][string[]]$Images,
	[Parameter(Mandatory = $true)][string]$CreativePrompt,
	[Parameter(Mandatory = $true)][string]$VisionModel,
	[string]$SamModel = $(if ($env:OFXGGML_SAM_MODEL) { $env:OFXGGML_SAM_MODEL } else { "" }),
	[string]$AceModelDir = $(if ($env:OFXGGML_ACESTEP_MODEL_DIR) { $env:OFXGGML_ACESTEP_MODEL_DIR } else { "" }),
	[string]$AceServerExecutable = "",
	[string]$AceServerUrl = "http://127.0.0.1:8085",
	[string]$OutputDir = "",
	[double]$SegmentDurationSeconds = 2.0,
	[switch]$KeepAceServer,
	[switch]$SkipSamBuild,
	[switch]$DryRun,
	[switch]$Json
)

$ErrorActionPreference = "Stop"

function ConvertFrom-StepJson {
	param([object[]]$Output, [string]$Name)
	$text = ($Output | ForEach-Object { $_.ToString() }) -join "`n"
	try { return $text | ConvertFrom-Json } catch { throw "$Name did not return valid JSON: $text" }
}

function Test-AceHealth {
	try {
		$status = Invoke-RestMethod -Uri ($AceServerUrl.TrimEnd("/") + "/health") -TimeoutSec 3
		return [string]$status.status -eq "ok"
	} catch { return $false }
}

function Wait-AceJob {
	param([string]$Id, [int]$TimeoutSeconds)
	$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
	do {
		$status = Invoke-RestMethod -Uri ($AceServerUrl.TrimEnd("/") + "/job?id=$Id") -TimeoutSec 30
		if ($status.status -eq "done") { return }
		if ($status.status -in @("failed", "cancelled")) {
			throw "ACE-Step job $Id $($status.status): $($status.error)"
		}
		Start-Sleep -Milliseconds 250
	} while ((Get-Date) -lt $deadline)
	throw "ACE-Step job $Id timed out"
}

function Write-AceSoundtrack {
	param([string]$Caption, [double]$DurationSeconds, [string]$OutputPath)
	$baseUrl = $AceServerUrl.TrimEnd("/")
	$request = @{
		caption = $Caption; lyrics = "[Instrumental]"; bpm = 90
		duration = $DurationSeconds; keyscale = "C major"; timesignature = "4/4"
		vocal_language = "en"; seed = 4242; batch_size = 1
		lm_temperature = 0.85; lm_cfg_scale = 2.0; lm_top_p = 0.9; lm_top_k = 0
		lm_negative_prompt = "vocals, speech, distortion"; use_cot_caption = $true
		audio_codes = ""; inference_steps = 8; guidance_scale = 1.0; shift = 3.0
		audio_cover_strength = 0.0; repainting_start = 0.0; repainting_end = 0.0
		lego = ""; output_format = "wav16"
	}
	$lmStart = Invoke-RestMethod -Uri "$baseUrl/lm" -Method Post -ContentType "application/json" -Body ($request | ConvertTo-Json -Depth 8) -TimeoutSec 60
	if ([string]::IsNullOrWhiteSpace([string]$lmStart.id)) { throw "ACE-Step /lm did not return a job id" }
	Wait-AceJob -Id $lmStart.id -TimeoutSeconds 600
	$lmResponse = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/job?id=$($lmStart.id)&result=1" -Headers @{ Accept = "application/json" } -TimeoutSec 60
	$lmPayload = ([string]$lmResponse.Content) | ConvertFrom-Json
	$lmResult = @($lmPayload)
	while ($lmResult.Count -eq 1 -and $lmResult[0] -is [Array]) { $lmResult = @($lmResult[0]) }
	if ($lmResult.Count -eq 1 -and $lmResult[0].PSObject.Properties['result']) { $lmResult = @($lmResult[0].result) }
	if ($lmResult.Count -lt 1) { throw "ACE-Step /lm returned no synthesis request" }
	if ([string]::IsNullOrWhiteSpace([string]$lmResult[0].caption)) { throw "ACE-Step /lm synthesis request is missing caption" }
	foreach ($item in $lmResult) {
		$item | Add-Member -NotePropertyName output_format -NotePropertyValue "wav16" -Force
		$item | Add-Member -NotePropertyName inference_steps -NotePropertyValue 8 -Force
		$item | Add-Member -NotePropertyName guidance_scale -NotePropertyValue 1.0 -Force
		$item | Add-Member -NotePropertyName shift -NotePropertyValue 3.0 -Force
	}
	$synthStart = Invoke-RestMethod -Uri "$baseUrl/synth" -Method Post -ContentType "application/json" -Headers @{ Accept = "audio/wav" } -Body ($lmResult | ConvertTo-Json -Depth 12) -TimeoutSec 120
	if ([string]::IsNullOrWhiteSpace([string]$synthStart.id)) { throw "ACE-Step /synth did not return a job id" }
	Wait-AceJob -Id $synthStart.id -TimeoutSeconds 1200
	$response = Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/job?id=$($synthStart.id)&result=1" -Headers @{ Accept = "audio/wav" } -TimeoutSec 120
	[byte[]]$bytes = $response.Content
	$riffOffset = -1
	for ($index = 0; $index -le $bytes.Length - 12; $index++) {
		if ($bytes[$index] -eq 82 -and $bytes[$index + 1] -eq 73 -and $bytes[$index + 2] -eq 70 -and $bytes[$index + 3] -eq 70 -and
			$bytes[$index + 8] -eq 87 -and $bytes[$index + 9] -eq 65 -and $bytes[$index + 10] -eq 86 -and $bytes[$index + 11] -eq 69) {
			$riffOffset = $index; break
		}
	}
	if ($riffOffset -lt 0) { throw "ACE-Step result did not contain RIFF/WAVE audio" }
	$wavLength = [BitConverter]::ToUInt32($bytes, $riffOffset + 4) + 8
	if ($riffOffset + $wavLength -gt $bytes.Length) { throw "ACE-Step returned a truncated WAV part" }
	[byte[]]$wav = New-Object byte[] $wavLength
	[Array]::Copy($bytes, $riffOffset, $wav, 0, $wavLength)
	[IO.File]::WriteAllBytes($OutputPath, $wav)
	return [ordered]@{ LmJob = $lmStart.id; SynthJob = $synthStart.id; Bytes = $wav.Length; AudioCodes = ([string]$lmResult[0].audio_codes).Split(',').Count }
}

function ConvertTo-ConcatPath {
	param([string]$Path)
	return ((Resolve-Path -LiteralPath $Path).Path.Replace('\', '/').Replace("'", "'\''"))
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workflowsRoot = Resolve-Path (Join-Path $scriptRoot "..")
$addonsRoot = Split-Path -Parent $workflowsRoot
$multimodalScript = Join-Path $scriptRoot "run-multimodal-reference-smoke.ps1"
$montageScript = Join-Path $addonsRoot "ofxGgmlVideo\scripts\run-model-informed-montage-smoke.ps1"
$aceStartScript = Join-Path $addonsRoot "ofxGgmlMusic\scripts\start-acestep-server.ps1"
$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
if ([string]::IsNullOrWhiteSpace($AceServerExecutable)) {
	$AceServerExecutable = Join-Path $addonsRoot "ofxGgmlMusic\libs\acestep\bin\ace-server.exe"
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
	$OutputDir = Join-Path ([IO.Path]::GetTempPath()) "ofxGgml-creative-reference-workflow"
}
$resolvedImages = @($Images | ForEach-Object { $_ -split ',' } | ForEach-Object {
	$path = $_.Trim()
	if (-not [string]::IsNullOrWhiteSpace($path)) { (Resolve-Path -LiteralPath $path).Path }
})
if ($resolvedImages.Count -lt 2) { throw "Pass at least two reference images" }
foreach ($required in @($multimodalScript, $montageScript, $aceStartScript, $AceServerExecutable)) {
	if (!(Test-Path -LiteralPath $required)) { throw "Required workflow input was not found: $required" }
}
foreach ($optionalModelInput in @($SamModel, $AceModelDir)) {
	if (-not [string]::IsNullOrWhiteSpace($optionalModelInput) -and !(Test-Path -LiteralPath $optionalModelInput)) {
		throw "Configured model input was not found: $optionalModelInput"
	}
}
if ($SegmentDurationSeconds -le 0) { throw "SegmentDurationSeconds must be greater than zero" }

if ($DryRun) {
	$plan = [ordered]@{ Name = "ofxGgml creative reference workflow"; Ready = $true; ModelBacked = $true; InferenceChecked = $false; Images = $resolvedImages; CreativePrompt = $CreativePrompt; VisionModel = $VisionModel; SamModel = $SamModel; AceModelDir = $AceModelDir; OutputDir = $OutputDir; FinalArtifact = "MP4" }
	if ($Json) { $plan | ConvertTo-Json -Depth 5 } else { $plan | Format-List }
	return
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$started = Get-Date
$startedAcePid = 0
try {
	$montageOutput = & $montageScript -Images $resolvedImages -MontagePrompt $CreativePrompt -VisionModel $VisionModel -SegmentDurationSeconds $SegmentDurationSeconds -Json 2>&1
	if (!$?) { throw "Model-informed montage failed: $(($montageOutput | ForEach-Object { $_.ToString() }) -join "`n")" }
	$montage = ConvertFrom-StepJson -Output $montageOutput -Name "Model-informed montage"
	if (!$montage.Passed -or $montage.SegmentCount -lt 2) { throw "Montage did not produce ranked segments" }
	$leadImage = [string]$montage.Segments[0].SourcePath
	$referenceOutput = & $multimodalScript -Image $leadImage -VisionModel $VisionModel -SamModel $SamModel -SkipSamBuild:$SkipSamBuild -Json 2>&1
	if (!$?) { throw "Multimodal reference analysis failed: $(($referenceOutput | ForEach-Object { $_.ToString() }) -join "`n")" }
	$reference = ConvertFrom-StepJson -Output $referenceOutput -Name "Multimodal reference analysis"
	if (!$reference.Passed -or $reference.Segmentation.MaskCount -lt 1) { throw "Reference analysis did not produce a mask" }

	if (!(Test-AceHealth)) {
		$aceStartArgs = @{
			ServerExecutable = $AceServerExecutable
			ServerUrl = $AceServerUrl
			StartupTimeoutSeconds = 90
		}
		if (-not [string]::IsNullOrWhiteSpace($AceModelDir)) { $aceStartArgs.ModelPath = $AceModelDir }
		$serverOutput = & $aceStartScript @aceStartArgs 2>&1
		if (!$?) { throw "ACE-Step server failed to start: $(($serverOutput | ForEach-Object { $_.ToString() }) -join "`n")" }
		$pidMatch = [regex]::Match((($serverOutput | ForEach-Object { $_.ToString() }) -join "`n"), "OFXGGML_ACESTEP_SERVER_PID=(\d+)")
		if ($pidMatch.Success) { $startedAcePid = [int]$pidMatch.Groups[1].Value }
	}
	if (!(Test-AceHealth)) { throw "ACE-Step server is not healthy at $AceServerUrl" }

	$soundtrackPath = Join-Path $OutputDir "soundtrack.wav"
	$musicCaption = "Instrumental soundtrack for $CreativePrompt. Visual reference: $($montage.Segments[0].VisionCaption)"
	$music = Write-AceSoundtrack -Caption $musicCaption -DurationSeconds ([double]$montage.DurationSeconds) -OutputPath $soundtrackPath
	$concatPath = Join-Path $OutputDir "timeline.txt"
	$concatLines = New-Object Collections.Generic.List[string]
	foreach ($segment in $montage.Segments) {
		$concatLines.Add("file '$(ConvertTo-ConcatPath -Path ([string]$segment.SourcePath))'")
		$concatLines.Add("duration $([double]$segment.DurationSeconds)")
	}
	$concatLines.Add("file '$(ConvertTo-ConcatPath -Path ([string]$montage.Segments[-1].SourcePath))'")
	[IO.File]::WriteAllLines($concatPath, $concatLines)
	$videoPath = Join-Path $OutputDir "creative-reference.mp4"
	$ffmpegArgs = @('-y','-f','concat','-safe','0','-i',$concatPath,'-i',$soundtrackPath,'-vf','scale=640:640:force_original_aspect_ratio=decrease,pad=640:640:(ow-iw)/2:(oh-ih)/2,format=yuv420p','-c:v','libx264','-tune','stillimage','-r','24','-c:a','aac','-shortest',$videoPath)
	$previousErrorActionPreference = $ErrorActionPreference
	try {
		$ErrorActionPreference = "Continue"
		$ffmpegOutput = @(& $ffmpeg @ffmpegArgs 2>&1 | ForEach-Object { $_.ToString() })
		$ffmpegExitCode = $LASTEXITCODE
	} finally {
		$ErrorActionPreference = $previousErrorActionPreference
	}
	if ($ffmpegExitCode -ne 0 -or !(Test-Path -LiteralPath $videoPath -PathType Leaf)) {
		throw "FFmpeg did not render the creative reference MP4: $($ffmpegOutput -join ' ')"
	}

	$summary = [ordered]@{
		Name = "ofxGgml creative reference workflow"; Passed = $true; ModelBacked = $true; InferenceChecked = $true
		CreativePrompt = $CreativePrompt; LeadImage = $leadImage; VisionCaption = $montage.Segments[0].VisionCaption
		MaskCount = [int]$reference.Segmentation.MaskCount; MaskActiveRatio = [double]$reference.Segmentation.FirstMaskActiveRatio
		Timeline = $montage.Segments; Soundtrack = $soundtrackPath; SoundtrackBytes = [int64]$music.Bytes
		AceLmJob = $music.LmJob; AceSynthJob = $music.SynthJob; Video = $videoPath; VideoBytes = (Get-Item $videoPath).Length
		ElapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
	}
	if ($Json) { $summary | ConvertTo-Json -Depth 8 } else { $summary | Format-List }
} finally {
	if ($startedAcePid -gt 0 -and !$KeepAceServer) {
		$process = Get-Process -Id $startedAcePid -ErrorAction SilentlyContinue
		if ($process -and $process.ProcessName -eq "ace-server") { Stop-Process -Id $startedAcePid -Force }
	}
}
