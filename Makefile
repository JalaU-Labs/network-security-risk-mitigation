.PHONY: setup up down scan validate test lint clean

setup:
	uv sync

up:
	docker compose up -d

down:
	docker compose down

scan:
	@echo "Running reconnaissance scans..."
	@bash scripts/scan.sh

validate:
	@echo "Validating mitigations..."
	@bash scripts/validate.sh

test:
	uv run pytest -v

lint:
	@echo "Linting Python with Ruff..."
	uv run ruff check .
	uv run ruff format --check .
	@echo "Linting YAML with Yamllint..."
	uv run yamllint -c .yamllint.yml docker-compose.yml .github/workflows/ .gitlab-ci.yml

clean:
	docker compose down -v
	rm -rf .venv
	rm -rf logs/