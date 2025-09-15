# Personal Ubuntu Scripts

A growing collection of small, single-purpose scripts I use on Ubuntu. Each script lives in its own folder with its own README and (optionally) LICENSE. The goal is to keep things simple, discoverable, and easy to run on a fresh system.

## Repository layout

- Each script is contained in its own folder at the repo root
  - `<script-name>/` — directory for a single script/tool
    - `README.md` — details, options, and what the script does
    - `*.sh` — the executable shell script(s)
    - `LICENSE` (optional) — license for that script if it differs or is specified per-folder

## Getting started

1. Browse the folders in this repository and open the one you need.
2. Read that folder's `README.md` to understand what the script does and any options or caveats.
3. Run the script from inside the folder. Typical options:

   ```bash
   # Make the script executable (if needed)
   chmod +x ./your-script.sh

   # Or run directly with bash
   bash ./your-script.sh
   ```

### Notes and recommendations

- Review scripts before running them, especially those that modify system settings or install packages.
- Prefer running in a test VM/container if you're unsure.
- Some scripts may require sudo; they'll prompt you when needed.

## Current scripts

<!-- scripts:start -->
- `make-ubuntu-windowsy/` — Make Ubuntu Windowsy

<!-- scripts:end -->

## Contributing / personal notes

- New scripts should follow the same folder-per-script pattern and include a minimal `README.md` explaining purpose, prerequisites, and usage.
- Keep scripts idempotent where practical and avoid destructive defaults.
- Prefer standard Ubuntu repositories/tools where possible; clearly call out any third-party sources.

## Licensing

Licensing may be defined per script folder (via a `LICENSE` file in that folder). Refer to each script's folder for its license and usage terms.
