param(
  [Parameter(Mandatory = $true)]
  [string]$AssetDirectory,

  [string]$OutputDirectory,

  [Parameter(Mandatory = $true)]
  [string]$Version,

  [Parameter(Mandatory = $true)]
  [string]$Tag,

  [Parameter(Mandatory = $true)]
  [string]$Repository
)

$ErrorActionPreference = 'Stop'

function Get-AssetInfo {
  param([System.IO.FileInfo]$File)

  $name = $File.Name
  if ($name -match '_Windows_.*_Setup\.exe$') {
    return [ordered]@{
      platform = 'windows'
      type = 'windows-installer'
      label = 'Windows 安装版'
      description = '推荐普通用户使用，支持应用内一键更新。'
    }
  }
  if ($name -match '_Windows_.*_Portable\.zip$') {
    return [ordered]@{
      platform = 'windows'
      type = 'windows-portable'
      label = 'Windows 便携版'
      description = '解压即用，支持应用内一键更新，适合放在自定义目录。'
    }
  }
  if ($name -match '_macOS_.*_Portable\.zip$') {
    return [ordered]@{
      platform = 'macos'
      type = 'macos-portable'
      label = 'macOS 版'
      description = '通用版（Apple 芯片 / Intel，macOS 13.5+），解压后拖进“应用程序”；应用内下载更新后在访达中替换。'
    }
  }
  return $null
}

function Get-ChangelogSection {
  param([string]$Version)

  $changelogPath = Join-Path (Resolve-Path ".") "CHANGELOG.md"
  if (-not (Test-Path -LiteralPath $changelogPath)) {
    return "本次发布见 CHANGELOG.md。"
  }

  $lines = Get-Content -Path $changelogPath -Encoding UTF8
  $headerPattern = '^##\s+(\[)?v?' + [regex]::Escape($Version) + '(\])?(\s|$)'
  $start = -1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $headerPattern) {
      $start = $i + 1
      break
    }
  }

  if ($start -lt 0) {
    return "本次发布见 CHANGELOG.md。"
  }

  $end = $lines.Count
  for ($i = $start; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^##\s+') {
      $end = $i
      break
    }
  }

  $section = $lines[$start..($end - 1)] -join [Environment]::NewLine
  if ([string]::IsNullOrWhiteSpace($section)) {
    return "本次发布见 CHANGELOG.md。"
  }
  return $section.Trim()
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
  $OutputDirectory = $AssetDirectory
}

$assetPath = Resolve-Path $AssetDirectory
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$outputPath = Resolve-Path $OutputDirectory

$releaseFiles = Get-ChildItem -Path $assetPath -File |
  Where-Object { $_.Extension -in @('.exe', '.zip') } |
  Sort-Object Name

if (-not $releaseFiles) {
  throw "No release assets were found in $assetPath"
}

$assets = @()
$checksumLines = @()
foreach ($file in $releaseFiles) {
  $assetInfo = Get-AssetInfo -File $file
  if (-not $assetInfo) {
    throw "Unknown release asset type: $($file.Name)"
  }

  $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  $downloadUrl = "https://github.com/$Repository/releases/download/$Tag/$([uri]::EscapeDataString($file.Name))"
  $checksumLines += "$hash  $($file.Name)"
  $assets += [ordered]@{
    platform = $assetInfo.platform
    type = $assetInfo.type
    fileName = $file.Name
    downloadUrl = $downloadUrl
    sha256 = $hash
    size = $file.Length
    label = $assetInfo.label
    description = $assetInfo.description
  }
}

$manifest = [ordered]@{
  version = $Version
  tag = $Tag
  publishedAt = (Get-Date).ToUniversalTime().ToString('o')
  assets = $assets
}

$manifestPath = Join-Path $outputPath "release_manifest.json"
$checksumsPath = Join-Path $outputPath "checksums.txt"
$notesPath = Join-Path $outputPath "release_notes_${Tag}.md"

$manifest |
  ConvertTo-Json -Depth 6 |
  Set-Content -Path $manifestPath -Encoding UTF8
$checksumLines |
  Set-Content -Path $checksumsPath -Encoding UTF8

function Get-DownloadBadge {
  param([System.Collections.IDictionary]$Asset)

  $type = $Asset['type']
  $url = $Asset['downloadUrl']
  switch ($type) {
    'windows-installer' {
      return "[![Windows Setup x64](https://img.shields.io/badge/Setup-x64-0078D4?style=flat-square&logo=windows11&logoColor=white)]($url)"
    }
    'windows-portable' {
      return "[![Windows Portable x64](https://img.shields.io/badge/Portable-x64-56B4D3?style=flat-square&logo=windows11&logoColor=white)]($url)"
    }
    'macos-portable' {
      return "[![macOS Universal ZIP](https://img.shields.io/badge/ZIP-Universal-555555?style=flat-square&logo=apple&logoColor=white)]($url)"
    }
    default {
      throw "Cannot create download badge for asset type: $type"
    }
  }
}

$windowsBadges = @(
  $assets |
    Where-Object { $_['platform'] -eq 'windows' } |
    ForEach-Object { Get-DownloadBadge -Asset $_ }
)
$macosBadges = @(
  $assets |
    Where-Object { $_['platform'] -eq 'macos' } |
    ForEach-Object { Get-DownloadBadge -Asset $_ }
)
$downloadRows = @()
if ($windowsBadges.Count -gt 0) {
  $downloadRows += "| **Windows** | $($windowsBadges -join '<br>') |"
}
if ($macosBadges.Count -gt 0) {
  $downloadRows += "| **macOS** | $($macosBadges -join '<br>') |"
}
$changelogSection = Get-ChangelogSection -Version ($Version -replace '\+.*$', '')

$releaseLines = @(
  "# W.O.F NAI Studio $Tag",
  "",
  "## 📥 按系统下载",
  "",
  "点击对应按钮直接下载：",
  "",
  "| OS | Download |",
  "| --- | --- |"
)
$releaseLines += $downloadRows
$releaseLines += @(
  "",
  "> **应用内更新：** Windows 安装版用户无需手动下载。应用会自动选择 Setup x64，完成下载与 SHA256 校验后退出旧版本、静默安装并重新启动。Portable 版也支持应用内自动更新和失败回滚。更新源为本仓库 Releases。",
  "",
  "> **安装提示：** Windows Setup 为普通用户的推荐版本，Portable 适合放在自定义目录。",
  ""
)
if ($macosBadges.Count -gt 0) {
  $releaseLines += @(
    '> **macOS 安装：** 通用包包含 Apple 芯片和 Intel 两种架构。完整包需要 macOS 13.5 或更新，应用主体的部署目标为 macOS 12。用访达解压后把 W.O.F NAI Studio 拖进“应用程序”。应用没有经过 Apple 公证：第一次打开时在访达里按住 Control 点按应用、选“打开”（macOS 15 起要到“系统设置 → 隐私与安全性”里点“仍要打开”）；如果提示“已损坏，无法打开”，在终端运行 `xattr -dr com.apple.quarantine "/Applications/W.O.F NAI Studio.app"` 后再打开。',
    '',
    '> **macOS 更新：** 应用内会下载并校验新版本，然后在访达中选中它；按 ⌘Q 退出旧版本，把新版本拖进“应用程序”替换即可。',
    ''
  )
}
$releaseLines += @(
  "## 📝 更新内容",
  "",
  $changelogSection,
  "",
  "## 🔐 文件校验",
  "",
  '本次 Release 附带 `checksums.txt` 和 `release_manifest.json`。应用内更新会同时校验文件大小与 SHA256，校验失败不会启动安装。'
)

$releaseNotes = $releaseLines -join [Environment]::NewLine

$releaseNotes | Set-Content -Path $notesPath -Encoding UTF8

Write-Host "Created release manifest: $manifestPath"
Write-Host "Created checksums: $checksumsPath"
Write-Host "Created release notes: $notesPath"
