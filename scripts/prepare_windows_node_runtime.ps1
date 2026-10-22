param(
  [Parameter(Mandatory)][string]$OutputDirectory
)
# CI preparation only. Packaging itself never downloads or resolves dependencies.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$archiveName = 'node-v24.18.0-win-x64.zip'
$baseUrl = 'https://nodejs.org/dist/v24.18.0'
$archive = Join-Path $OutputDirectory $archiveName
Invoke-WebRequest "$baseUrl/$archiveName" -OutFile $archive
$checksums = (Invoke-WebRequest "$baseUrl/SHASUMS256.txt").Content
$expected = [regex]::Match($checksums, "(?m)^([a-f0-9]{64})\s+$([regex]::Escape($archiveName))\s*$").Groups[1].Value
if (-not $expected -or (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
  throw 'Official Node runtime archive checksum mismatch.'
}
Expand-Archive -LiteralPath $archive -DestinationPath $OutputDirectory -Force
$nodeFolder = Join-Path $OutputDirectory 'node-v24.18.0-win-x64'
Copy-Item (Join-Path $nodeFolder 'node.exe') (Join-Path $OutputDirectory 'node.exe') -Force
Copy-Item (Join-Path $nodeFolder 'LICENSE') (Join-Path $OutputDirectory 'NODE-LICENSE') -Force
Push-Location (Join-Path $root 'tool/nai_agent')
try {
  & (Join-Path $nodeFolder 'npm.cmd') ci
  if ($LASTEXITCODE -ne 0) { throw 'Agent npm ci failed.' }
} finally { Pop-Location }
$license = Join-Path $root 'tool/nai_agent/node_modules/@earendil-works/pi-coding-agent/LICENSE'
if (-not (Test-Path $license)) { $license = Join-Path $root 'tool/nai_agent/PI-LICENSE' }
if (-not (Test-Path $license)) { throw 'Pi license not found.' }
Copy-Item $license (Join-Path $OutputDirectory 'PI-LICENSE') -Force
Write-Host "Prepared Node 24.18.0 + Pi license: $OutputDirectory"
