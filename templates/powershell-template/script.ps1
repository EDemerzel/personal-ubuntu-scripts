#!/usr/bin/env pwsh

<#
.SYNOPSIS
    {{DESCRIPTION}}

.DESCRIPTION
    {{SCRIPT_NAME}} - {{DESCRIPTION}}

    Author: {{AUTHOR}}
    Created: {{DATE}}

.PARAMETER Help
    Show help information

.PARAMETER Debug
    Enable debug output

.EXAMPLE
    ./{{SCRIPT_NAME}}.{{EXTENSION}}
    Run the script with default settings

.EXAMPLE
    ./{{SCRIPT_NAME}}.{{EXTENSION}} -Debug
    Run the script with debug output enabled

.NOTES
    Requires PowerShell 7+ for cross-platform compatibility
    On Ubuntu/Linux: sudo snap install powershell --classic
#>

[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$Debug
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script metadata
$Script:ScriptName = "{{SCRIPT_NAME}}"
$Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Script:DebugMode = $Debug -or $PSBoundParameters.ContainsKey('Debug')

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White",
        [string]$Prefix = ""
    )

    if ($Prefix) {
        Write-Host "$Prefix " -ForegroundColor $ForegroundColor -NoNewline
    }
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-InfoMessage {
    param([string]$Message)
    Write-ColorOutput -Message $Message -ForegroundColor "Cyan" -Prefix "ℹ️"
}

function Write-SuccessMessage {
    param([string]$Message)
    Write-ColorOutput -Message $Message -ForegroundColor "Green" -Prefix "✅"
}

function Write-WarningMessage {
    param([string]$Message)
    Write-ColorOutput -Message $Message -ForegroundColor "Yellow" -Prefix "⚠️"
    Write-Warning $Message
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput -Message $Message -ForegroundColor "Red" -Prefix "❌"
    Write-Error $Message -ErrorAction Continue
}

function Write-DebugMessage {
    param([string]$Message)
    if ($Script:DebugMode) {
        Write-ColorOutput -Message "DEBUG: $Message" -ForegroundColor "Magenta" -Prefix "🔍"
    }
}

# Help function
function Show-Help {
    Get-Help $MyInvocation.MyCommand.Definition -Detailed
}

# Function to check if running as administrator (Windows) or root (Linux/macOS)
function Test-IsElevated {
    if ($IsWindows) {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } else {
        return (id -u) -eq 0
    }
}

# Function to check dependencies
function Test-Dependencies {
    $deps = @("git", "curl")  # Example dependencies
    $missing = @()

    foreach ($dep in $deps) {
        if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
            $missing += $dep
        }
    }

    if ($missing.Count -gt 0) {
        Write-ErrorMessage "Missing required dependencies: $($missing -join ', ')"
        return $false
    }

    return $true
}

# Function to validate environment
function Test-Environment {
    Write-DebugMessage "Validating environment..."

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-WarningMessage "PowerShell 7+ recommended for best compatibility. Current version: $($PSVersionTable.PSVersion)"
    }

    # Check platform
    Write-DebugMessage "Platform: $($PSVersionTable.Platform)"
    Write-DebugMessage "OS: $($PSVersionTable.OS)"

    # Uncomment if elevated privileges are required
    # if (Test-IsElevated) {
    #     Write-ErrorMessage "This script should not be run with elevated privileges"
    #     return $false
    # }

    # Uncomment if dependency check is needed
    # if (-not (Test-Dependencies)) {
    #     return $false
    # }

    return $true
}

# Main script logic
function Invoke-MainScript {
    Write-InfoMessage "Starting {{SCRIPT_NAME}}"
    Write-DebugMessage "Debug mode enabled"

    try {
        # Validate environment
        if (-not (Test-Environment)) {
            throw "Environment validation failed"
        }

        # Your script logic here
        Write-InfoMessage "Hello from {{SCRIPT_NAME}}!"

        # Example: Process files, make API calls, etc.
        Write-DebugMessage "Processing main functionality..."

        Write-SuccessMessage "{{SCRIPT_NAME}} completed successfully"
    }
    catch {
        Write-ErrorMessage "Script execution failed: $($_.Exception.Message)"
        Write-DebugMessage "Full error details: $($_.Exception | Format-List -Force | Out-String)"
        exit 1
    }
}

# Script entry point
function Main {
    # Handle help parameter
    if ($Help) {
        Show-Help
        return
    }

    # Execute main script logic
    Invoke-MainScript
}

# Only run main if script is executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
