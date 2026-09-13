# --- Developer notebook tools ---

.PHONY: setup unit-tests linter precommit-check

setup:
	python3 -m venv .venv
	.venv/bin/pip install -e ".[dev]"

unit-tests:
	@echo "Running unit tests..."
	.venv/bin/pytest -m "not integration"

linter:
	@echo "Running ruff..."
	.venv/bin/ruff check src tests

precommit-check: linter unit-tests
