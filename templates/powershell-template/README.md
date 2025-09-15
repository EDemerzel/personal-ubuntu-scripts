# {{SCRIPT_NAME}}

{{DESCRIPTION}}

## Prerequisites

- PowerShell 7+ (Cross-platform PowerShell)
- On Ubuntu/Linux: `sudo snap install powershell --classic`
- On Windows: PowerShell is included
- On macOS: `brew install powershell/tap/powershell`

## Usage

```powershell
# Make the script executable (Linux/macOS)
chmod +x ./{{SCRIPT_NAME}}.{{EXTENSION}}

# Run the script
./{{SCRIPT_NAME}}.{{EXTENSION}}

# Run with debug output
./{{SCRIPT_NAME}}.{{EXTENSION}} -Debug

# Show help
./{{SCRIPT_NAME}}.{{EXTENSION}} -Help
```

### Windows Usage

```powershell
# Run the script
.\{{SCRIPT_NAME}}.{{EXTENSION}}

# Run with debug output
.\{{SCRIPT_NAME}}.{{EXTENSION}} -Debug

# Show help
Get-Help .\{{SCRIPT_NAME}}.{{EXTENSION}} -Detailed
```

## Parameters

- `-Help`: Show detailed help information
- `-Debug`: Enable debug output for troubleshooting

## What it does

Detailed explanation of what the script accomplishes:

1. Step one
2. Step two
3. etc.

## Cross-Platform Compatibility

This PowerShell script is designed to work on:

- ✅ **Windows** (PowerShell 5.1+ and PowerShell 7+)
- ✅ **Linux** (PowerShell 7+)
- ✅ **macOS** (PowerShell 7+)

## Safety notes

- Does this script require elevated privileges?
- Does it modify system files?
- Any other important warnings or considerations

## Error Handling

The script includes comprehensive error handling:

- Strict mode enabled for better error detection
- Structured try-catch blocks
- Detailed error messages with debug information
- Graceful failure with appropriate exit codes

## License

See `LICENSE` file in this directory.
