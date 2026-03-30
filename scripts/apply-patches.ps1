param(
    [Parameter(Mandatory = $true)]
    [string]$UpstreamRepo
)

$resolvedRepo = (Resolve-Path -LiteralPath $UpstreamRepo).Path
$patchDir = Join-Path $PSScriptRoot '..\patches'
$patchDir = (Resolve-Path -LiteralPath $patchDir).Path

if (-not (Test-Path -LiteralPath (Join-Path $resolvedRepo '.git'))) {
    throw "Not a git repository: $resolvedRepo"
}

$patches = @(
    (Join-Path $patchDir '0001-add-configurable-stream-retry-settings.patch'),
    (Join-Path $patchDir '0002-default-stream-retries-to-fixed-1s.patch')
)

& git -C $resolvedRepo am @patches
if ($LASTEXITCODE -ne 0) {
    throw "git am failed with exit code $LASTEXITCODE"
}

Write-Host "Applied fixed-retry patch set to $resolvedRepo"
