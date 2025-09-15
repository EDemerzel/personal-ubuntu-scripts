# {{SCRIPT_NAME}}

{{DESCRIPTION}}

## Description

Business automation Python script created on {{DATE}} by {{AUTHOR}}.

## Requirements

- Python 3.8 or higher
- Standard library modules (no additional dependencies by default)

## Installation

1. Ensure Python 3.8+ is installed:

   ```bash
   python3 --version
   ```

2. Make the script executable (Linux/macOS):

   ```bash
   chmod +x {{SCRIPT_NAME}}.py
   ```

## Usage

Run the script with Python:

```bash
# Basic usage
python3 {{SCRIPT_NAME}}.py

# With verbose output
python3 {{SCRIPT_NAME}}.py --verbose

# Dry run (show what would be done)
python3 {{SCRIPT_NAME}}.py --dry-run

# Using custom configuration
python3 {{SCRIPT_NAME}}.py --config /path/to/config.json

# Show help
python3 {{SCRIPT_NAME}}.py --help
```

Or run directly (if executable):

```bash
./{{SCRIPT_NAME}}.py --verbose
```

## Configuration

The script can be configured using a JSON configuration file. By default, it looks for:

- `~/.config/{{SCRIPT_NAME}}.json`

Example configuration:

```json
{
  "setting1": "value1",
  "setting2": true,
  "setting3": 42
}
```

## Features

- Comprehensive argument parsing with help text
- Configurable logging (info/debug levels)
- Configuration file support (JSON)
- Dry run mode for safe testing
- Cross-platform compatibility
- Error handling and graceful exit codes
- Type hints for better code quality

## Exit Codes

- `0`: Success
- `1`: General error
- `130`: Interrupted by user (Ctrl+C)

## Development

### Code Quality

The script follows Python best practices:

- Type hints for function parameters and return values
- Comprehensive error handling
- Structured logging
- Configuration management
- Command-line argument parsing

### Testing

Test the script with various scenarios:

```bash
# Test help output
python3 {{SCRIPT_NAME}}.py --help

# Test verbose mode
python3 {{SCRIPT_NAME}}.py --verbose

# Test dry run
python3 {{SCRIPT_NAME}}.py --dry-run

# Test with non-existent config
python3 {{SCRIPT_NAME}}.py --config /tmp/nonexistent.json
```

### Extending

To add functionality:

1. Add command-line arguments in the `main()` function
2. Implement your logic in the main function
3. Use the provided utility functions:
   - `run_command()` for executing shell commands
   - `load_config()` for configuration management
   - `setup_logging()` for logging configuration

## Author

{{AUTHOR}} ({{YEAR}})
