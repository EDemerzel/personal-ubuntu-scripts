#!/usr/bin/env pwsh

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path -Path (Join-Path $PSScriptRoot '..')).Path
$ReadmePath = Join-Path $Root 'README.md'
$StartMark = '<!-- scripts:start -->'
$EndMark = '<!-- scripts:end -->'
$Ignore = @('.git', '.github', '.vscode', 'bin')

function Get-FirstMeaningfulLine {
  param([string]$FilePath)
  if (-not (Test-Path -Path $FilePath -PathType Leaf)) { return $null }
  $lines = Get-Content -Path $FilePath -Raw -ErrorAction Stop -Encoding UTF8 |
    ForEach-Object { $_ -split "`r?`n" }
  foreach ($l in $lines) {
    $t = $l.Trim()
    if ([string]::IsNullOrWhiteSpace($t)) { continue }
    # strip markdown heading markers
    return ($t -replace '^\s*#+\s*', '')
  }
  return $null
}

function Get-ScriptType {
  param([string]$Dir)
  $has = @()
  if (Get-ChildItem -Path $Dir -Filter '*.sh' -File -ErrorAction SilentlyContinue) { $has += 'Bash' }
  if (Get-ChildItem -Path $Dir -Filter '*.ps1' -File -ErrorAction SilentlyContinue) { $has += 'PowerShell' }
  if (Get-ChildItem -Path $Dir -Filter '*.py' -File -ErrorAction SilentlyContinue) { $has += 'Python' }
  return $has
}

function Format-MarkdownLine {
  param([string]$DirName)
  $path = Join-Path $Root $DirName
  $summary = Get-FirstMeaningfulLine -FilePath (Join-Path $path 'README.md')
  if (-not $summary) {
    $types = @((Get-ScriptType -Dir $path))
    if ($types.Count -gt 1) {
      $last = $types[-1]
      $list = ($types[0..($types.Count - 2)] -join ', ')
      $summary = if ($list) { "$list and $last scripts" } else { "$last scripts" }
    } elseif ($types.Count -eq 1) {
      $summary = "$($types[0]) scripts"
    } else {
      $summary = 'Scripts'
    }
  }
  # Build markdown line with backticks around folder name (ASCII only)
  return ('- `' + $DirName + '/` - ' + $summary)
}

# Collect first-level directories
$dirs = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -notin $Ignore } | Sort-Object Name

# Build section
$sectionLines = @()
foreach ($d in $dirs) {
  $hasReadme = Test-Path -Path (Join-Path $d.FullName 'README.md') -PathType Leaf
  $hasScripts = @(
    Get-ChildItem -Path $d.FullName -File -Filter '*.sh' -ErrorAction SilentlyContinue
    Get-ChildItem -Path $d.FullName -File -Filter '*.ps1' -ErrorAction SilentlyContinue
    Get-ChildItem -Path $d.FullName -File -Filter '*.py' -ErrorAction SilentlyContinue
  ).Count -gt 0
  if ($hasReadme -or $hasScripts) {
    $sectionLines += (Format-MarkdownLine -DirName $d.Name)
  }
}
$sectionText = ($sectionLines -join "`n")

# Replace between markers in README
$content = Get-Content -Path $ReadmePath -Raw -Encoding UTF8
$pattern = "(?s)($([regex]::Escape($StartMark))).*?($([regex]::Escape($EndMark)))"
$replacement = "`$1`n$sectionText`n`$2"
$newContent = [regex]::Replace($content, $pattern, $replacement)

Set-Content -Path $ReadmePath -Value $newContent -Encoding UTF8 -NoNewline:$false
Write-Output 'Updated Current scripts section in README.md'
