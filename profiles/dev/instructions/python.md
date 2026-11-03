# Python Instructions

## Toolchain
- Runtime: python3 + pip (system)
- Virtual env: `python3 -m venv .venv`
- Package manager: pip / pip-tools / poetry

## Commands
- Run: `python3 -m <module>`
- Test: `python3 -m pytest tests/ -v`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy src/`
- Install: `pip install -r requirements.txt` or `pip install -e .`

## Conventions
- Use snake_case for functions/variables
- Use PascalCase for classes
- Type hints обязательны для публичных функций
- Используй dataclasses для DTO
- Prefer pathlib over os.path

## Verify
```bash
python3 --version && pip --version && ruff --version && mypy --version
```
