param([string]$OutputDirectory = 'build/bridge-client')
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$destination = [IO.Path]::GetFullPath((Join-Path $workspace $OutputDirectory))
if (-not $destination.StartsWith($workspace + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Bridge client output must stay inside this source workspace.'
}
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$clientSource = Join-Path $workspace 'tool/studio_bridge.dart'
$clientExecutable = Join-Path $destination 'studio-bridge.exe'
Push-Location $workspace
try {
  & dart compile exe $clientSource -o $clientExecutable
  if ($LASTEXITCODE -ne 0) { throw 'Bridge client compilation failed.' }
  & $clientExecutable --help | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Bridge client help check failed.' }
} finally { Pop-Location }
Write-Host "Built standalone bridge client: $clientExecutable"
