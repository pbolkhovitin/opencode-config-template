# Bash Instructions

## Toolchain
- Shell: bash 5.x
- Lint: shellcheck
- Formatter: shfmt

## Commands
- Lint: `shellcheck script.sh`
- Format: `shfmt -w script.sh`
- Run: `bash script.sh`

## Conventions
- Shebang: `#!/usr/bin/env bash`
- Set: `set -euo pipefail` at the top
- Functions: `my_func() { ... }`
- Variables: lowercase for locals, UPPERCASE for exports/constants
- Quote all variable expansions: `"$var"`, `"${array[@]}"`
- Prefer `[[ ]]` over `[ ]` for conditionals
- Trap EXIT for cleanup: `trap cleanup EXIT`
- Use `mktemp` for temporary files
- Avoid `eval` — always

## Verify
```bash
bash --version && shellcheck --version && shfmt --version
```
