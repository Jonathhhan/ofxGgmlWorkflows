param(
	[Parameter(Mandatory = $true)]
	[string] $Image,
	[string] $VisionModel = $(if ($env:OFXGGML_VISION_SERVER_MODEL) { $env:OFXGGML_VISION_SERVER_MODEL } else { "" }),
	[string] $VisionServerUrl = $(if ($env:OFXGGML_VISION_SERVER_URL) { $env:OFXGGML_VISION_SERVER_URL } else { "http://127.0.0.1:11434" }),
	[string] $VisionPrompt = "Describe the predominant colors and the main central shape in this image. Be concrete and concise.",
	[string] $SamModel = $(if ($env:OFXGGML_SAM_MODEL) { $env:OFXGGML_SAM_MODEL } else { "" }),
	[string] $SamBuildDir = "",
	[ValidateSet("cpu", "cuda")]
	[string] $SamBackend = "cpu",
	[switch] $SkipSamBuild,
	[switch] $DryRun,
	[switch] $Json
)

$ErrorActionPreference = "Stop"

function Resolve-JsonOutput {
	param([object[]] $Output, [string] $Step)
	$text = ($Output | ForEach-Object { $_.ToString() }) -join "`n"
	try {
		return $text | ConvertFrom-Json
	} catch {
		throw "$Step did not return valid JSON: $text"
	}
}

function Convert-ToRgbPpm {
	param([string] $SourcePath, [string] $TargetPath)
	Add-Type -AssemblyName System.Drawing
	$bitmap = [System.Drawing.Bitmap]::new($SourcePath)
	try {
		$stream = [System.IO.File]::Open($TargetPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
		try {
			$header = [System.Text.Encoding]::ASCII.GetBytes("P6`n$($bitmap.Width) $($bitmap.Height)`n255`n")
			$stream.Write($header, 0, $header.Length)
			$row = [byte[]]::new($bitmap.Width * 3)
			for ($y = 0; $y -lt $bitmap.Height; $y++) {
				for ($x = 0; $x -lt $bitmap.Width; $x++) {
					$pixel = $bitmap.GetPixel($x, $y)
					$offset = $x * 3
					$row[$offset] = $pixel.R
					$row[$offset + 1] = $pixel.G
					$row[$offset + 2] = $pixel.B
				}
				$stream.Write($row, 0, $row.Length)
			}
		} finally {
			$stream.Dispose()
		}
	} finally {
		$bitmap.Dispose()
	}
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workflowsRoot = Resolve-Path (Join-Path $scriptRoot "..")
$addonsRoot = Split-Path -Parent $workflowsRoot
$visionRoot = Join-Path $addonsRoot "ofxGgmlVision"
$samRoot = Join-Path $addonsRoot "ofxGgmlSam"
$visionScript = Join-Path $visionRoot "scripts\run-vision-server-smoke.ps1"
$samScript = Join-Path $samRoot "scripts\run-sam3-runtime-smoke.ps1"
$resolvedImage = [Environment]::ExpandEnvironmentVariables($Image)
if (-not [System.IO.Path]::IsPathRooted($resolvedImage)) {
	$resolvedImage = Join-Path $workflowsRoot $resolvedImage
}
if (-not (Test-Path -LiteralPath $resolvedImage -PathType Leaf)) {
	throw "Reference image was not found: $resolvedImage"
}
if (-not (Test-Path -LiteralPath $visionScript -PathType Leaf)) {
	throw "Vision smoke script was not found: $visionScript"
}
if (-not (Test-Path -LiteralPath $samScript -PathType Leaf)) {
	throw "SAM3 smoke script was not found: $samScript"
}
if ([string]::IsNullOrWhiteSpace($VisionModel)) {
	throw "Pass -VisionModel or set OFXGGML_VISION_SERVER_MODEL."
}
if ([string]::IsNullOrWhiteSpace($SamBuildDir)) {
	$SamBuildDir = Join-Path ([System.IO.Path]::GetTempPath()) "ofxGgmlSam3-runtime-smoke"
}

if ($DryRun) {
	$plan = [ordered]@{
		Name = "ofxGgml multimodal reference smoke"
		Ready = $true
		Image = (Resolve-Path -LiteralPath $resolvedImage).Path
		VisionModel = $VisionModel
		VisionServerUrl = $VisionServerUrl
		SamModel = $SamModel
		SamBackend = $SamBackend
		SamBuildDir = $SamBuildDir
		ModelBacked = $true
		InferenceChecked = $false
	}
	if ($Json) { $plan | ConvertTo-Json -Depth 5 } else { $plan | Format-List }
	return
}

$started = Get-Date
$vision = $null
$visionOutput = @()
$visionAttempt = 0
for ($attempt = 1; $attempt -le 2; $attempt++) {
	$visionAttempt = $attempt
	$visionOutput = & $visionScript `
		-ServerUrl $VisionServerUrl `
		-Model $VisionModel `
		-Image $resolvedImage `
		-Prompt $VisionPrompt `
		-Json `
		-SummaryOnly 2>&1
	$visionSucceeded = $?
	$vision = Resolve-JsonOutput -Output $visionOutput -Step "Vision smoke"
	if ($visionSucceeded -and $vision.Passed -and -not [string]::IsNullOrWhiteSpace([string] $vision.Text)) {
		break
	}
}
if (-not $vision.Passed -or [string]::IsNullOrWhiteSpace([string] $vision.Text)) {
	throw "Vision model-backed smoke failed after $visionAttempt attempts: $(($visionOutput | ForEach-Object { $_.ToString() }) -join "`n")"
}

$samImage = $resolvedImage
$temporarySamImage = ""
if ([System.IO.Path]::GetExtension($resolvedImage) -notin @(".ppm", ".pnm")) {
	$temporarySamImage = Join-Path ([System.IO.Path]::GetTempPath()) ("ofxggml-sam-reference-{0}.ppm" -f [guid]::NewGuid().ToString("N"))
	Convert-ToRgbPpm -SourcePath $resolvedImage -TargetPath $temporarySamImage
	$samImage = $temporarySamImage
}

$samArgs = @{
	Backend = $SamBackend
	BuildDir = $SamBuildDir
	Image = $samImage
	Json = $true
	SummaryOnly = $true
}
if (-not [string]::IsNullOrWhiteSpace($SamModel)) { $samArgs.Model = $SamModel }
if ($SkipSamBuild) { $samArgs.SkipBuild = $true }
$samOutput = & $samScript @samArgs 2>&1
$samSucceeded = $?
if (-not [string]::IsNullOrWhiteSpace($temporarySamImage) -and (Test-Path -LiteralPath $temporarySamImage)) {
	Remove-Item -LiteralPath $temporarySamImage -Force
}
if (-not $samSucceeded) {
	throw "SAM3 model-backed smoke failed: $(($samOutput | ForEach-Object { $_.ToString() }) -join "`n")"
}
$sam = Resolve-JsonOutput -Output $samOutput -Step "SAM3 smoke"
$samSummary = $sam.Summary
if (-not $samSummary.Passed -or -not $samSummary.InferenceChecked -or [int] $samSummary.MaskCount -lt 1) {
	throw "SAM3 smoke did not produce a model-backed mask."
}

$summary = [ordered]@{
	Name = "ofxGgml multimodal reference smoke"
	Passed = $true
	ModelBacked = $true
	InferenceChecked = $true
	Image = (Resolve-Path -LiteralPath $resolvedImage).Path
	Vision = [ordered]@{
		Model = $vision.Model
		Backend = $vision.Backend
		Text = $vision.Text
		Attempts = $visionAttempt
		ElapsedMs = $vision.ElapsedMs
	}
	Segmentation = [ordered]@{
		ModelPath = $samSummary.ModelPath
		Backend = $samSummary.Backend
		MaskCount = $samSummary.MaskCount
		FirstMaskWidth = $samSummary.FirstMaskWidth
		FirstMaskHeight = $samSummary.FirstMaskHeight
		FirstMaskActivePixels = $samSummary.FirstMaskActivePixels
		FirstMaskActiveRatio = $samSummary.FirstMaskActiveRatio
		TotalMs = $samSummary.TotalMs
	}
	ElapsedMs = [int] ((Get-Date) - $started).TotalMilliseconds
}

if ($Json) {
	$summary | ConvertTo-Json -Depth 6
} else {
	Write-Host "ofxGgml multimodal reference smoke passed"
	Write-Host "Vision: $($summary.Vision.Text)"
	Write-Host "Masks: $($summary.Segmentation.MaskCount); active ratio: $($summary.Segmentation.FirstMaskActiveRatio)"
}
