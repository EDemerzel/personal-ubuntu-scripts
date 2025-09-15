#!/usr/bin/env pwsh

[CmdletBinding()]
param(
  [switch]$PowerShell,
  [switch]$Python,
  [Parameter(Position = 0, Mandatory = $true)]
  [ValidatePattern('^[a-z0-9]([a-z0-9-]*[a-z0-9])?$')]
  [string]$Name,
  [Parameter(Position = 1)]
  [string]$Description
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path -Path (Join-Path $PSScriptRoot '..')).Path
$TplBash = Join-Path $Root 'templates/script-template'
$TplPS = Join-Path $Root 'templates/powershell-template'
$TplPy = Join-Path $Root 'templates/python-template'

if (-not $Description) {
  if ($PowerShell) { $Description = 'A useful PowerShell script' }
  elseif ($Python) { $Description = 'A useful Python script' }
  else { $Description = 'A useful Ubuntu script' }
}

$Target = Join-Path $Root $Name
if (Test-Path -Path $Target) { throw "Directory '$Name' already exists" }

$author = (git config user.name 2>$null) ; if (-not $author) { $author = $env:USER }
$year = (Get-Date).ToString('yyyy')
$date = (Get-Date).ToString('yyyy-MM-dd')

# Select template
$tpl = if ($PowerShell) { $TplPS } elseif ($Python) { $TplPy } else { $TplBash }
$ext = if ($PowerShell) { 'ps1' } elseif ($Python) { 'py' } else { 'sh' }

New-Item -ItemType Directory -Path $Target | Out-Null

# Copy template excluding LICENSE (business branch)
if (Get-Command rsync -ErrorAction SilentlyContinue) {
  & rsync -a --exclude 'LICENSE' (Join-Path $tpl '.') (Join-Path $Target '.')
} else {
  Get-ChildItem -Path $tpl -Force | Where-Object { $_.Name -ne 'LICENSE' } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $Target -Recurse -Force
  }
}

# Rename main script
$srcMain = Join-Path $Target ('script.' + $ext)
$dstMain = Join-Path $Target ($Name + '.' + $ext)
Move-Item -Path $srcMain -Destination $dstMain

# Replace placeholders in files
Get-ChildItem -Path $Target -File | ForEach-Object {
  $content = Get-Content -Raw -LiteralPath $_.FullName -Encoding 'utf8'
  $content = $content.Replace('{{SCRIPT_NAME}}', $Name)
  $content = $content.Replace('{{DESCRIPTION}}', $Description)
  $content = $content.Replace('{{AUTHOR}}', $author)
  $content = $content.Replace('{{YEAR}}', $year)
  $content = $content.Replace('{{DATE}}', $date)
  $content = $content.Replace('{{EXTENSION}}', $ext)
  Set-Content -LiteralPath $_.FullName -Value $content -Encoding 'utf8'
}

# Make executable for Bash/Python
if (-not $PowerShell) {
  & chmod +x $dstMain 2>$null
}

Write-Output "Created script directory: $Name/"
Write-Output 'Files created:'
Write-Output '  - {0}/README.md' -f $Name
if ($PowerShell) {
  Write-Output '  - {0}/{0}.ps1' -f $Name
} elseif ($Python) {
  Write-Output '  - {0}/{0}.py (executable)' -f $Name
} else {
  Write-Output '  - {0}/{0}.sh (executable)' -f $Name
}

# Update README
$lsScript = Join-Path $Root 'bin/list-scripts.sh'
if (Test-Path -Path $lsScript -PathType Leaf) { & $lsScript }
else { Write-Warning "Run './bin/list-scripts.sh' to update the scripts list" }
