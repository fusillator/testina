# --- Developer notebook tools ---

YELLOW := \033[33m
RESET  := \033[0m

.PHONY: setup unit-tests linter precommit-check

setup:
	python3 -m venv .venv
	.venv/bin/pip install -e ".[dev]"

unit-tests:
	@printf "$(YELLOW)Running unit tests...$(RESET)\n"
	.venv/bin/pytest -m "not integration"

linter:
	@printf "$(YELLOW)Running ruff...$(RESET)\n"
	.venv/bin/ruff check src tests

precommit-check: linter unit-tests
