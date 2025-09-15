#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Fully clean a .NET repository by removing bin/ and obj/ folders.

.DESCRIPTION
    Given a repository path, this script searches for a solution (.sln) file
    and deletes all bin/ and obj/ directories under that path.

.PARAMETER RepoPath
    The path to the .NET repository root.

.PARAMETER Confirm
    Prompt for confirmation before deletion.

.PARAMETER WhatIf
    Show what would be deleted without deleting anything.

.EXAMPLE
    ./dotnet-full-clean.ps1 -RepoPath /path/to/repo -Verbose

.NOTES
    Internal business automation script.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$RepoPath,

  [switch]$Confirm,
  [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ANSI color sequences for output (PowerShell 7+ terminals)
$esc = [char]27
$Cyan = "$esc[36m"
$Green = "$esc[32m"
$Reset = "$esc[0m"

function Write-Info {
  param([string]$Message)
  Write-Output ('{0}{1}{2}' -f $Cyan, $Message, $Reset)
}

function Write-Success {
  param([string]$Message)
  Write-Output ('{0}{1}{2}' -f $Green, $Message, $Reset)
}

function Write-Warn {
  param([string]$Message)
  Write-Warning $Message
}

function Write-Err {
  param([string]$Message)
  Write-Error $Message -ErrorAction Continue
}

# Resolve and validate path
$RepoPath = (Resolve-Path -Path $RepoPath).Path
if (-not (Test-Path -Path $RepoPath -PathType Container)) {
  throw "Repository path not found or not a directory: $RepoPath"
}

Write-Info "Target repository: $RepoPath"

# Find solution file (top-level preferred, else first found)
$solution = Get-ChildItem -Path $RepoPath -Filter '*.sln' -File -ErrorAction SilentlyContinue |
  Select-Object -First 1
if (-not $solution) {
  $solution = Get-ChildItem -Path $RepoPath -Recurse -Filter '*.sln' -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
}
if ($solution) {
  Write-Info "Found solution: $($solution.FullName)"
} else {
  Write-Warn 'No .sln file found in the repository.'
}

# Enumerate bin/ and obj/ folders
$targets = @()
$targets += Get-ChildItem -Path $RepoPath -Recurse -Directory -Filter 'bin' -ErrorAction SilentlyContinue
$targets += Get-ChildItem -Path $RepoPath -Recurse -Directory -Filter 'obj' -ErrorAction SilentlyContinue

if (-not $targets -or $targets.Count -eq 0) {
  Write-Info 'No bin/ or obj/ folders found to clean.'
  exit 0
}

Write-Info ('Found {0} directories to remove' -f $targets.Count)

# Confirm or WhatIf support
$PSBoundParameters['WhatIf'] = [bool]$WhatIf
if ($Confirm) {
  $Host.UI.Write('Proceed to delete these directories? [y/N]: ')
  $resp = Read-Host
  if ($resp -notin @('y', 'Y', 'yes', 'YES')) {
    Write-Info 'Aborted by user.'
    exit 0
  }
}

foreach ($dir in $targets) {
  $path = $dir.FullName
  if ($PSCmdlet.ShouldProcess($path, 'Remove-Item -Recurse -Force')) {
    try {
      Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
      Write-Success "Removed: $path"
    } catch {
      Write-Err "Failed to remove '$path': $($_.Exception.Message)"
    }
  }
}

Write-Info 'Done.'
