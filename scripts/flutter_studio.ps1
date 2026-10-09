[CmdletBinding()]
param(
  [string]$SdkRoot,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$checkoutRoot = Split-Path -Parent $PSScriptRoot
$expected = Get-Content -LiteralPath (Join-Path $checkoutRoot 'tool/flutter-sdk.json') -Raw |
  ConvertFrom-Json

# 新 SDK 单独登记，保留系统 PATH 上的 SDK 供已有审查会话使用。
if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
  $SdkRoot = $env:WOF_FLUTTER_SDK_ROOT
}
if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
  $candidates = @(
    (Join-Path $checkoutRoot "../../sdk/flutter-$($expected.flutterVersion)"),
    (Join-Path $checkoutRoot "../.devin/sdk/flutter-$($expected.flutterVersion)")
  )
  $SdkRoot = $candidates | Where-Object {
    Test-Path -LiteralPath (Join-Path $_ 'bin/flutter.bat') -PathType Leaf
  } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
  throw '未找到登记的 Flutter SDK。请传入 -SdkRoot 或设置 WOF_FLUTTER_SDK_ROOT。'
}
$SdkRoot = (Resolve-Path -LiteralPath $SdkRoot).Path
$flutterTool = Join-Path $SdkRoot 'bin/flutter.bat'
if (-not (Test-Path -LiteralPath $flutterTool -PathType Leaf)) {
  throw "Flutter 工具不存在：$flutterTool"
}

$versionOutput = & $flutterTool --no-version-check --suppress-analytics --version --machine
if ($LASTEXITCODE -ne 0) {
  throw "Flutter 版本核验失败，退出码 $LASTEXITCODE。"
}
$actual = ($versionOutput -join "`n") | ConvertFrom-Json
foreach ($field in @('flutterVersion', 'frameworkRevision', 'engineRevision', 'dartSdkVersion')) {
  if ($actual.$field -ne $expected.$field) {
    throw "SDK 不匹配：$field 实际为 $($actual.$field)，登记值为 $($expected.$field)。"
  }
}

if (-not $FlutterArgs -or $FlutterArgs.Count -eq 0) {
  $FlutterArgs = @('--version')
}
Write-Host "Studio SDK: Flutter $($actual.flutterVersion) / Dart $($actual.dartSdkVersion) ($SdkRoot)"
& $flutterTool --no-version-check --suppress-analytics @FlutterArgs
exit $LASTEXITCODE
