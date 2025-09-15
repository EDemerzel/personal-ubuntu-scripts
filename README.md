# Business Scripts

A curated collection of internal, business-focused automation scripts. Each script lives in its own folder with its own README. The goal is to keep things simple, repeatable, and safe to run across business environments.

## Language Support

This repository supports **Bash**, **PowerShell**, and **Python** scripts:

- **Bash scripts** (`.sh`) — Traditional shell scripts for Ubuntu/Linux environments
- **PowerShell scripts** (`.ps1`) — Cross-platform PowerShell 7+ scripts that work on Linux, macOS, and Windows
- **Python scripts** (`.py`) — Python 3.8+ scripts with comprehensive tooling and best practices

Scripts are organized by purpose, not language, so you'll find the best tool for each task regardless of implementation language.

## Repository layout

- Each script is contained in its own folder at the repo root
  - `<script-name>/` — directory for a single script/tool
    - `README.md` — details, options, and what the script does
    - `*.sh` — executable shell script(s) (Bash)
    - `*.ps1` — executable PowerShell script(s) (PowerShell 7+)
    - `*.py` — executable Python script(s) (Python 3.8+)
  - Any additional supporting files specific to the script

## Getting started

1. Browse the folders in this repository and open the one you need.
2. Read that folder's `README.md` to understand what the script does and any options or caveats.
3. Run the script from inside the folder:

   **For Bash scripts:**

   ```bash
   # Make the script executable (if needed)
   chmod +x ./your-script.sh

   # Or run directly with bash
   bash ./your-script.sh
   ```

   **For PowerShell scripts:**

   ```bash
   # Run with PowerShell (requires PowerShell 7+ installed)
   pwsh ./your-script.ps1

   # Or make executable and run directly (Linux/macOS)
   chmod +x ./your-script.ps1
   ./your-script.ps1
   ```

   **For Python scripts:**

   ```bash
   # Run with Python (requires Python 3.8+ installed)
   python3 ./your-script.py

   # Or make executable and run directly (Linux/macOS)
   chmod +x ./your-script.py
   ./your-script.py

   # With additional arguments
   python3 ./your-script.py --verbose --dry-run
   ```

### Notes and recommendations

- **PowerShell 7+ Installation:** For PowerShell scripts, ensure PowerShell 7+ is installed:

  ```bash
  # Ubuntu/Debian
  sudo apt install powershell

  # Or via snap
  sudo snap install powershell --classic
  ```

- **Python 3.8+ Installation:** For Python scripts, ensure Python 3.8+ is installed:

  ```bash
  # Ubuntu/Debian (usually pre-installed)
  sudo apt install python3 python3-pip

  # Install common linting tools (optional)
  pip3 install flake8 black mypy
  ```

- Review scripts before running them, especially those that modify system settings or install packages.
- Prefer running in a test VM/container if you're unsure.
- Some scripts may require sudo; they'll prompt you when needed.

## Current scripts

<!-- scripts:start -->
- `dotnet-full-clean/` - dotnet-full-clean
<!-- scripts:end -->

## Adding new scripts

Use the scaffolding tool to create new business script directories:

```bash
./bin/new-script.sh [--powershell|--python] <script-name> [description]
```

**Creating Bash scripts (default):**

```bash
./bin/new-script.sh backup-dotfiles "Backup user dotfiles to cloud storage"
./bin/new-script.sh setup-dev-env "Configure development environment"
```

**Creating PowerShell scripts:**

```bash
./bin/new-script.sh --powershell backup-dotfiles "Backup user dotfiles to cloud storage"
./bin/new-script.sh --powershell setup-dev-env "Configure development environment"
```

**Creating Python scripts:**

```bash
./bin/new-script.sh --python data-processor "Process and analyze data files"
./bin/new-script.sh --python system-monitor "Monitor system resources and generate reports"
```

This creates a new folder with:

- `README.md` template with placeholders filled in
- `<script-name>.sh`, `<script-name>.ps1`, or `<script-name>.py` executable with boilerplate and best practices
- Automatically updates this README's script list

## Contributing / internal notes

- New scripts should follow the same folder-per-script pattern and include a minimal `README.md` explaining purpose, prerequisites, and usage.
- Keep scripts idempotent where practical and avoid destructive defaults.
- Prefer standard repositories/tools where possible; clearly call out any third-party sources.

## Usage and distribution

These scripts are intended for internal business use. Distribution outside the organization should be reviewed and approved.

