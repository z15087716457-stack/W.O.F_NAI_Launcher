param()
$ErrorActionPreference = 'Stop'
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$output = Join-Path $sourceRoot 'assets/rag/windows'
$build = Join-Path $sourceRoot '.dart_tool/rag-host-build'
New-Item -ItemType Directory -Force -Path $output,$build | Out-Null
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $installation) { throw 'Visual Studio C++ tools not found' }
$vcvars = Join-Path $installation 'VC/Auxiliary/Build/vcvars64.bat'
$cpp = Join-Path $PSScriptRoot 'stdio_host.cpp'
$exe = Join-Path $output 'stdio_host.exe'
$obj = Join-Path $build 'stdio_host.obj'
foreach ($checkedPath in @($vcvars,$cpp,$exe,$obj,$build)) {
  if ($checkedPath -match '["\r\n]') { throw 'Unsupported character in build path' }
}
$command = @"
@echo off
call "$vcvars" >nul
cl /nologo /std:c++17 /O2 /MT /EHsc /DUNICODE /D_UNICODE "$cpp" /Fe:"$exe" /Fo:"$obj" /link /IMPLIB:"$build/stdio_host.lib"
exit /b %errorlevel%
"@
$commandPath = Join-Path $build 'build.cmd'
[IO.File]::WriteAllText($commandPath,$command.Replace("`r`n","`n").Replace("`n","`r`n"),[Text.Encoding]::ASCII)
& $env:ComSpec /d /c $commandPath
if ($LASTEXITCODE -ne 0) { throw 'RAG host compilation failed' }
Get-FileHash -LiteralPath $exe -Algorithm SHA256
