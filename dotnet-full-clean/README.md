# dotnet-full-clean

Clean a .NET repository by removing all `bin/` and `obj/` folders recursively and locating the solution file for reference.

## Description

This business automation script helps you fully clean a .NET repo by deleting build artifacts. It can locate the `.sln` file and logs what it does.

## Usage

```powershell
# Run (PowerShell 7+ recommended)
pwsh ./dotnet-full-clean.ps1 -RepoPath /path/to/repo -Verbose
```

### Parameters

- `-RepoPath` (required): Path to the root of the .NET repository to clean.
- `-Confirm` (switch): Prompt for confirmation before deleting.
- `-WhatIf` (switch): Show what would be deleted without deleting.

## Notes

- Intended for internal business use.
- Requires permissions to delete directories under the target repo.
