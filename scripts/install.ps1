param(
    [string]$Repository = $(if ($env:CODEX_FIXED_RETRY_REPO) { $env:CODEX_FIXED_RETRY_REPO } else { 'constansino/codex-fixed-retry' })
)

$archCandidates = switch ($env:PROCESSOR_ARCHITECTURE) {
    'ARM64' { @('aarch64-pc-windows-msvc', 'x86_64-pc-windows-msvc') }
    'AMD64' { @('x86_64-pc-windows-msvc') }
    default { throw "Unsupported Windows architecture: $env:PROCESSOR_ARCHITECTURE" }
}

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest"
$asset = $null
foreach ($candidate in $archCandidates) {
    $name = "codex-fixed-retry-$candidate.zip"
    $asset = $release.assets | Where-Object { $_.name -eq $name } | Select-Object -First 1
    if ($asset) {
        break
    }
}

if (-not $asset) {
    throw "Could not find a Windows release asset for $($env:PROCESSOR_ARCHITECTURE) in $Repository"
}

$installRoot = Join-Path $HOME '.local\share\codex-fixed-retry\current'
$binDir = Join-Path $HOME '.local\bin'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-fixed-retry-" + [System.Guid]::NewGuid().ToString('N'))
$archivePath = Join-Path $tempRoot $asset.name

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
if (Test-Path -LiteralPath $installRoot) {
    Remove-Item -LiteralPath $installRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $installRoot, $binDir | Out-Null

Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
Expand-Archive -LiteralPath $archivePath -DestinationPath $installRoot -Force

$cmdShim = Join-Path $binDir 'codex.cmd'
$psShim = Join-Path $binDir 'codex.ps1'
$exePath = Join-Path $installRoot 'codex.exe'

$cmdContents = "@echo off`r`n`"$exePath`" %*`r`n"
$psContents = @"
$exe = '$exePath'
& $exe @args
exit $LASTEXITCODE
"@

Set-Content -LiteralPath $cmdShim -Value $cmdContents -Encoding ASCII
Set-Content -LiteralPath $psShim -Value $psContents -Encoding ASCII

Remove-Item -LiteralPath $tempRoot -Recurse -Force

Write-Host "Installed patched Codex to $installRoot"
Write-Host "Shims written to $cmdShim and $psShim"

if (-not (($env:Path -split ';') -contains $binDir)) {
    Write-Host "Add $binDir to PATH before your system Codex install if needed."
}
