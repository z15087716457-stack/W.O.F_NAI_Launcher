param(
  [string]$Version,
  [string]$DisplayVersion,
  [switch]$SkipFlutterBuild,
  [string]$DistDir = 'dist',
  [string]$NodeRuntimeDirectory = 'E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/tools/nai-agent',
  [string]$CrtDirectory
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
  $pubspecVersion = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
  if (-not $Version) { $Version = $pubspecVersion }
  if (-not $DisplayVersion) { $DisplayVersion = $pubspecVersion -replace '\+.*$', '' }
  if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?$' -or
      $DisplayVersion -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
    throw 'Version / DisplayVersion must be safe semantic versions.'
  }
  if ($env:CI -and -not $PSBoundParameters.ContainsKey('NodeRuntimeDirectory')) {
    throw 'CI must explicitly pass -NodeRuntimeDirectory (node.exe, NODE-LICENSE, PI-LICENSE).'
  }
  if (-not (Test-Path -LiteralPath $NodeRuntimeDirectory -PathType Container)) {
    throw "Node runtime not found: $NodeRuntimeDirectory. Pass -NodeRuntimeDirectory containing Node 24.18.0 node.exe, NODE-LICENSE and PI-LICENSE."
  }
  $NodeRuntimeDirectory = (Resolve-Path -LiteralPath $NodeRuntimeDirectory).Path
  $python = (Get-Command 'python' -ErrorAction Stop).Source
  $helper = Join-Path $PSScriptRoot 'windows_release_payload.py'
  function Invoke-Payload {
    & $python $helper @args
    if ($LASTEXITCODE -ne 0) { throw "Release payload operation failed: $args" }
  }
  Invoke-Payload preflight --root $root --runtime $NodeRuntimeDirectory

  if (-not $CrtDirectory) {
    $vsRoots = @()
    $vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
    if (Test-Path -LiteralPath $vswhere) {
      $vsRoots += @(& $vswhere -all -products '*' -property installationPath)
    }
    foreach ($base in @("${env:ProgramFiles}/Microsoft Visual Studio", "${env:ProgramFiles(x86)}/Microsoft Visual Studio")) {
      if (Test-Path -LiteralPath $base) {
        $vsRoots += @(Get-ChildItem -Path "$base/*/*" -Directory | ForEach-Object FullName)
      }
    }
    $candidates = @($vsRoots | Select-Object -Unique | ForEach-Object {
      Get-ChildItem -Path "$_/VC/Redist/MSVC/*/x64/Microsoft.VC14*.CRT" -Directory -ErrorAction SilentlyContinue
    } | Sort-Object -Property @{Expression = { [version]$_.Parent.Parent.Name }; Descending = $true})
    if (-not $candidates.Count) { throw 'Microsoft x64 CRT not found. Install VS C++ redist or pass -CrtDirectory.' }
    $CrtDirectory = $candidates[0].FullName
  }
  $crtNames = @('concrt140.dll', 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll',
    'msvcp140_atomic_wait.dll', 'msvcp140_codecvt_ids.dll', 'vccorlib140.dll',
    'vcruntime140.dll', 'vcruntime140_1.dll', 'vcruntime140_threads.dll')
  foreach ($name in $crtNames) {
    $source = Join-Path $CrtDirectory $name
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing x64 CRT: $source" }
    if ((Get-AuthenticodeSignature -LiteralPath $source).Status -ne 'Valid') {
      throw "CRT signature is not Valid: $source"
    }
  }

  # CI owns pub get and codegen. Packaging must not mutate dependency resolution
  # or regenerate business code; require all declared generated parts beforehand.
  if (-not (Test-Path '.dart_tool/package_config.json')) { throw 'Missing package_config.json; CI must resolve dependencies first.' }
  foreach ($file in Get-ChildItem lib -Filter '*.dart' -File -Recurse) {
    foreach ($part in [regex]::Matches([IO.File]::ReadAllText($file.FullName), "(?m)^part\s+'([^']+\.(?:g|freezed)\.dart)';")) {
      $generated = Join-Path $file.DirectoryName $part.Groups[1].Value
      if (-not (Test-Path -LiteralPath $generated)) { throw "Missing generated file: $generated. CI must run codegen before packaging." }
    }
  }
  if (-not $SkipFlutterBuild) {
    & (Join-Path $PSScriptRoot 'verify_nuget.ps1')
    # gen-l10n has no --no-pub option and does not resolve packages.
    & flutter gen-l10n
    if ($LASTEXITCODE -ne 0) { throw 'flutter gen-l10n failed.' }
    & flutter build windows --release --no-pub --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) { throw 'Flutter Windows release build failed.' }
  }

  $release = Join-Path $root 'build/windows/x64/runner/Release'
  if (-not (Test-Path (Join-Path $release 'nai_launcher.exe'))) { throw "Release executable not found: $release" }
  $folder = "WOF_NAI_Studio_$DisplayVersion"
  $stageRelative = "build/release-stage/$folder"
  $stage = Join-Path $root $stageRelative
  $dist = if ([IO.Path]::IsPathRooted($DistDir)) { [IO.Path]::GetFullPath($DistDir) } else { [IO.Path]::GetFullPath((Join-Path $root $DistDir)) }
  if ($dist.StartsWith((Join-Path $root 'build/windows'), [StringComparison]::OrdinalIgnoreCase) -or
      $dist.StartsWith((Join-Path $root 'build/release-stage'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'DistDir must be outside the Flutter release and staging directories.'
  }
  Invoke-Payload stage --root $root --release $release --stage $stage --runtime $NodeRuntimeDirectory
  & (Join-Path $PSScriptRoot 'build_bridge_client.ps1') -OutputDirectory "$stageRelative/tools"

  $crtReport = @()
  foreach ($name in $crtNames) {
    $source = Join-Path $CrtDirectory $name
    $target = Join-Path $stage $name
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $existing = Test-Path -LiteralPath $target
    if (-not $existing) { Copy-Item -LiteralPath $source -Destination $target }
    $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    if ((Get-AuthenticodeSignature -LiteralPath $target).Status -ne 'Valid') { throw "Staged CRT signature is not Valid: $target" }
    $crtReport += [ordered]@{file = $name; sourceSha256 = $sourceHash; stagedSha256 = $targetHash; keptFlutterOutput = $existing; hashesEqual = ($sourceHash -eq $targetHash); signature = 'Valid'}
    Write-Host "CRT $name keptFlutterOutput=$existing hashesEqual=$($sourceHash -eq $targetHash)"
  }
  $stageParent = Split-Path $stage -Parent
  $crtJson = Join-Path $stageParent 'crt-validation.json'
  ConvertTo-Json -InputObject @($crtReport) -Depth 4 | Set-Content -LiteralPath $crtJson -Encoding UTF8
  $flutterJson = Join-Path $stageParent 'flutter-version.json'
  & flutter --version --machine | Set-Content -LiteralPath $flutterJson -Encoding UTF8
  if ($LASTEXITCODE -ne 0) { throw 'Cannot read Flutter SDK version.' }
  Invoke-Payload finish --root $root --stage $stage --version $Version --display $DisplayVersion --flutter-json $flutterJson --crt-json $crtJson
  & (Join-Path $PSScriptRoot 'validate_windows_data_identity.ps1') -ExecutablePath (Join-Path $stage 'nai_launcher.exe')

  New-Item -ItemType Directory -Path $dist -Force | Out-Null
  $portable = Join-Path $dist "WOF_NAI_Studio_Windows_${DisplayVersion}_Portable.zip"
  $installer = Join-Path $dist "WOF_NAI_Studio_Windows_${DisplayVersion}_Setup.exe"
  Invoke-Payload zip --stage $stage --output $portable
  $makensis = (Get-Command 'makensis.exe' -ErrorAction SilentlyContinue).Source
  if (-not $makensis) { $makensis = "${env:ProgramFiles(x86)}/NSIS/makensis.exe" }
  if (-not (Test-Path -LiteralPath $makensis)) { throw 'makensis.exe not found; install NSIS.' }
  & $makensis /INPUTCHARSET UTF8 "/DVERSION=$DisplayVersion" "/DBUILD_VERSION=$Version" "/DSOURCE_DIR=$stage" "/DOUT_FILE=$installer" (Join-Path $root 'installer/windows/nai_launcher.nsi')
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $installer)) { throw 'NSIS installer compilation failed.' }
  Invoke-Payload checksums --output $installer --output $portable
  Write-Host "Created Windows installer: $installer"
  Write-Host "Created Windows portable package: $portable"
} finally {
  Pop-Location
}
