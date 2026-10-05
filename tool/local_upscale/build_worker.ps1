param([Parameter(Mandatory=$true)][string]$SdkDirectory)
$ErrorActionPreference = 'Stop'
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$sdkRoot = (Resolve-Path -LiteralPath $SdkDirectory).Path
$vswherePath = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
$vsRoot = & $vswherePath -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsRoot) { throw 'Visual Studio C++ Build Tools are required.' }
$vcvarsPath = Join-Path $vsRoot 'VC/Auxiliary/Build/vcvars64.bat'
$includePath = Join-Path $sdkRoot 'include'
$libraryPath = Join-Path $sdkRoot 'lib/Windows/x64'
foreach ($requiredPath in @((Join-Path $includePath 'nvsdk_ngx.h'), (Join-Path $libraryPath 'nvsdk_ngx_s.lib'))) {
  if (-not (Test-Path -LiteralPath $requiredPath)) { throw "Missing SDK build input: $requiredPath" }
}
$buildPath = Join-Path $sourceRoot '.dart_tool/advanced-worker-build'
$assetPath = Join-Path $sourceRoot 'assets/local_upscale/windows/studio_upscale_worker.exe'
$cppPath = Join-Path $PSScriptRoot 'studio_upscale_worker.cpp'
foreach ($checkedPath in @($sourceRoot, $sdkRoot, $vcvarsPath, $buildPath, $assetPath, $cppPath)) {
  if ($checkedPath -match '["\r\n]') { throw 'Unsupported character in build path.' }
}
New-Item -ItemType Directory -Path $buildPath -Force | Out-Null
$commandPath = Join-Path $buildPath 'build.cmd'
$commandText = @"
@echo off
call "$vcvarsPath" > nul
cl /nologo /std:c++17 /O2 /MT /EHsc /DUNICODE /D_UNICODE /I"$includePath" "$cppPath" /Fe:"$assetPath" /Fo:"$buildPath/worker.obj" /link /LIBPATH:"$libraryPath" nvsdk_ngx_s.lib d3d11.lib dxgi.lib windowscodecs.lib ole32.lib advapi32.lib shell32.lib shlwapi.lib user32.lib /IMPLIB:"$buildPath/worker.lib"
exit /b %errorlevel%
"@
[IO.File]::WriteAllText($commandPath, $commandText.Replace("`r`n", "`n").Replace("`n", "`r`n"), [Text.Encoding]::ASCII)
& $env:ComSpec /d /c $commandPath
if ($LASTEXITCODE -ne 0) { throw "Worker compilation failed: $LASTEXITCODE" }
Get-FileHash -LiteralPath $assetPath -Algorithm SHA256
