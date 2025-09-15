#!/usr/bin/env python3
"""
{{SCRIPT_NAME}} - {{DESCRIPTION}}

A Python script created from template on {{DATE}}.

Author: {{AUTHOR}}
Created: {{DATE}}
License: MIT
"""

import argparse
import json
import logging
import subprocess
import sys
import traceback
from pathlib import Path
from typing import Any, Dict, List, Optional


def setup_logging(verbose: bool = False) -> logging.Logger:
    """Set up logging configuration."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger(__name__)


def check_requirements() -> bool:
    """Check if all required dependencies are available."""
    logger = logging.getLogger(__name__)

    # Check Python version
    if sys.version_info < (3, 8):
        logger.error("Python 3.8 or higher is required")
        return False

    # Add additional requirement checks here
    # Example:
    # try:
    #     import requests
    # except ImportError:
    #     logger.error("requests library is required. Install with: "
    #                  "pip install requests")
    #     return False

    logger.debug("All requirements satisfied")
    return True


def run_command(command: List[str],
                cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
    """
    Run a shell command safely and return the result.

    Args:
        command: List of command parts
        cwd: Working directory for the command

    Returns:
        CompletedProcess object with result

    Raises:
        subprocess.CalledProcessError: If command fails
    """
    logger = logging.getLogger(__name__)
    logger.debug("Running command: %s", ' '.join(command))

    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True
        )
        logger.debug("Command output: %s", result.stdout.strip())
        return result
    except subprocess.CalledProcessError as e:
        logger.error("Command failed: %s", e)
        logger.error("stderr: %s", e.stderr)
        raise


def load_config(config_path: Path) -> Dict[str, Any]:
    """
    Load configuration from a JSON file.

    Args:
        config_path: Path to the configuration file

    Returns:
        Dictionary containing configuration
    """
    logger = logging.getLogger(__name__)

    if not config_path.exists():
        logger.warning("Configuration file %s not found, using defaults",
                       config_path)
        return {}

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        logger.debug("Loaded configuration from %s", config_path)
        return config
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON in configuration file %s: %s",
                     config_path, e)
        return {}
    except (OSError, IOError) as e:
        logger.error("Error reading configuration file %s: %s", config_path, e)
        return {}


def main() -> int:
    """Main function implementing the script logic."""
    # Set up argument parsing
    parser = argparse.ArgumentParser(
        description="{{DESCRIPTION}}",
        epilog="Example usage: python {{SCRIPT_NAME}}.py --verbose"
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be done without making changes'
    )

    parser.add_argument(
        '--config',
        type=Path,
        default=(Path.home() / '.config' /
                 '{{SCRIPT_NAME}}.json'),
        help='Path to configuration file'
    )

    # Add your custom arguments here
    # parser.add_argument('input_file', type=Path, help='Input file to process')
    # parser.add_argument('--output', '-o', type=Path, help='Output file path')

    args = parser.parse_args()

    # Set up logging
    logger = setup_logging(args.verbose)
    logger.info("Starting {{SCRIPT_NAME}}")

    try:
        # Check requirements
        if not check_requirements():
            logger.error("Requirements check failed")
            return 1

        # Load configuration
        config = load_config(args.config)

        # Use configuration values if available
        # Example: timeout = config.get('timeout', 30)
        logger.debug("Loaded config with %d entries", len(config))

        if args.dry_run:
            logger.info("DRY RUN MODE - No changes will be made")

        # Implement your script logic here
        # This template provides a foundation with:
        # - Argument parsing with argparse
        # - Structured logging with configurable levels
        # - Configuration file support (JSON format)
        # - Error handling and graceful exit codes
        # - Dry run mode for safe testing
        # - Command execution utilities

        # Example usage of configuration:
        # if config.get('enable_feature'):
        #     logger.info("Feature enabled via configuration")

        logger.info("Script logic not yet implemented")

        # Example of using the utility functions:
        # result = run_command(['ls', '-la'])
        # print(result.stdout)

        logger.info("{{SCRIPT_NAME}} completed successfully")
        return 0

    except KeyboardInterrupt:
        logger.warning("Script interrupted by user")
        return 130
    except (OSError, ValueError) as e:
        logger.error("Handled error: %s", e)
        if args.verbose:
            traceback.print_exc()
        return 1
    except Exception as e:
        logger.error("Unexpected error: %s", e)
        if args.verbose:
            traceback.print_exc()
        raise


if __name__ == '__main__':
    sys.exit(main())
