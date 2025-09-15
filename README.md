# Personal Ubuntu Scripts

A growing collection of small, single-purpose scripts I use on Ubuntu. Each script lives in its own folder with its own README and (optionally) LICENSE. The goal is to keep things simple, discoverable, and easy to run on a fresh system.

## Language Support

This repository supports both **Bash** and **PowerShell** scripts:

- **Bash scripts** (`.sh`) — Traditional shell scripts for Ubuntu/Linux environments
- **PowerShell scripts** (`.ps1`) — Cross-platform PowerShell 7+ scripts that work on Linux, macOS, and Windows

Scripts are organized by purpose, not language, so you'll find the best tool for each task regardless of implementation language.

## Repository layout

- Each script is contained in its own folder at the repo root
  - `<script-name>/` — directory for a single script/tool
    - `README.md` — details, options, and what the script does
    - `*.sh` — executable shell script(s) (Bash)
    - `*.ps1` — executable PowerShell script(s) (PowerShell 7+)
    - `LICENSE` (optional) — license for that script if it differs or is specified per-folder

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

### Notes and recommendations

- **PowerShell 7+ Installation:** For PowerShell scripts, ensure PowerShell 7+ is installed:

  ```bash
  # Ubuntu/Debian
  sudo apt install powershell

  # Or via snap
  sudo snap install powershell --classic
  ```

- Review scripts before running them, especially those that modify system settings or install packages.
- Prefer running in a test VM/container if you're unsure.
- Some scripts may require sudo; they'll prompt you when needed.

## Current scripts

<!-- scripts:start -->
- `make-ubuntu-windowsy/` — Make Ubuntu Windowsy

<!-- scripts:end -->

## Adding new scripts

Use the scaffolding tool to create new script directories:

```bash
./bin/new-script.sh <script-name> [description]
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

This creates a new folder with:

- `README.md` template with placeholders filled in
- `LICENSE` file (MIT by default)
- `<script-name>.sh` or `<script-name>.ps1` executable with boilerplate and best practices
- Automatically updates this README's script list

## Contributing / personal notes

- New scripts should follow the same folder-per-script pattern and include a minimal `README.md` explaining purpose, prerequisites, and usage.
- Keep scripts idempotent where practical and avoid destructive defaults.
- Prefer standard Ubuntu repositories/tools where possible; clearly call out any third-party sources.

## Licensing

Licensing may be defined per script folder (via a `LICENSE` file in that folder). Refer to each script's folder for its license and usage terms.
