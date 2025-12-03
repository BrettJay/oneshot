# AGENTS.md

## Project Overview
Timelapse screenshot capture utility for macOS. Single bash script (`timelapse.sh`) that captures screenshots at intervals for video creation. See README.md for full usage documentation.

## Commands
```bash
# Check syntax
bash -n timelapse.sh

# Make executable
chmod +x timelapse.sh

# Test run
./timelapse.sh test -i 5
```

## Code Style
- Shell: Bash with `set -euo pipefail` for strict error handling
- Use `[[ ]]` for conditionals, not `[ ]`
- Quote all variable expansions: `"$VAR"`
- Use lowercase for local variables, UPPERCASE for constants/globals
- Include usage/help function with examples
- Handle signals (SIGINT/SIGTERM) for clean exit
