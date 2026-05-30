# Workflow Metadata Extractor
# Extracts metadata from GitHub Actions workflow files

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkflowPath,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

# Read workflow file
$content = Get-Content -LiteralPath $WorkflowPath -Raw -Encoding UTF8

# Build metadata from workflow structure
$metadata = @{}

# Extract workflow name
if ($content -match '(?m)^name:\s*(.+)') {
    $metadata['workflow_name'] = $Matches[1].Trim()
}

# Extract trigger types from on: block
# Only capture direct children of on: (exactly 2-space indent)
if ($content -match '(?m)^on:\s*\n((?:[ \t]+.*\n?)*)') {
    $onBlock = $Matches[1]
    $triggers = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $onBlock -split "`n") {
        if ($line -match '^  ([a-zA-Z_][a-zA-Z0-9_]*)\s*:') {
            $trigger = $Matches[1]
            if ($trigger -notin $triggers) {
                $triggers.Add($trigger)
            }
        }
    }
    if ($triggers.Count -gt 0) {
        $metadata['triggers'] = ($triggers -join ', ')
    }
}

# Check for workflow_call (reusable)
if ($content -match 'workflow_call') {
    $metadata['type'] = 'reusable'
} else {
    $metadata['type'] = 'standalone'
}

# Count inputs for reusable workflows
# Inputs sit under on: workflow_call: inputs: with 6-space indent followed by 8-space type:
if ($content -match '(?m)^\s+inputs:') {
    $inputCount = ([regex]::Matches($content, '(?m)^\s{6}[\w-]+:\s*\r?\n\s{8}type:')).Count
    $metadata['input_count'] = $inputCount
}

# Check for matrix strategy
if ($content -match '(?m)matrix:') {
    $metadata['has_matrix'] = $true
}

# Extract runs-on targets
$runsOn = [System.Collections.Generic.List[string]]::new()
foreach ($match in [regex]::Matches($content, '(?m)^\s+runs-on:\s*(.+)')) {
    $val = $match.Groups[1].Value.Trim()
    if ($val -and $val -notin $runsOn) {
        $runsOn.Add($val)
    }
}
if ($runsOn.Count -gt 0) {
    $metadata['runs_on'] = ($runsOn -join ', ')
}

# Add file metadata
$metadata['file_path'] = $WorkflowPath
$metadata['file_size_bytes'] = (Get-Item $WorkflowPath).Length
$metadata['last_modified'] = (Get-Item $WorkflowPath).LastWriteTime.ToString('yyyy-MM-ddTHH:mm:ssZ')

# Output JSON
if ($metadata.Count -gt 0) {
    $json = $metadata | ConvertTo-Json -Depth 10
    if ($OutputPath) {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($OutputPath, "$json`n", $utf8NoBom)
        Write-Output "Metadata extracted from $WorkflowPath"
        Write-Output "Output written to: $OutputPath"
    } else {
        $json
    }
}
