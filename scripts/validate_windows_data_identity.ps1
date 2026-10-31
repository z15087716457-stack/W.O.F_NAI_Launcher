param(
  [string]$ExecutablePath = (Join-Path $PSScriptRoot '..\build\windows\x64\runner\Release\nai_launcher.exe')
)

$ErrorActionPreference = 'Stop'
$executable = Get-Item -LiteralPath $ExecutablePath
$version = $executable.VersionInfo

# These PE fields identify old AppData profiles for the one-time migration.
# FileDescription and the window title are the independent, visible brand name.
if ($version.CompanyName -cne 'com.example' -or $version.ProductName -cne 'nai_launcher') {
  throw 'Windows storage identity changed: CompanyName/ProductName must remain com.example/nai_launcher.'
}
if ($version.FileDescription -cne 'W.O.F NAI Studio') {
  throw 'The executable does not contain the current Studio display name.'
}

[pscustomobject]@{
  Executable = $executable.FullName
  DisplayName = $version.FileDescription
  StorageIdentity = "$($version.CompanyName)/$($version.ProductName)"
  ApplicationSupportDirectory = Join-Path $executable.DirectoryName 'user-data'
  LegacyApplicationSupportDirectory = Join-Path $env:APPDATA 'com.example\nai_launcher'
} | ConvertTo-Json
