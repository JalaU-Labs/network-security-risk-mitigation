.PHONY: setup up down scan test lint clean

setup:
	uv sync

up:
	docker compose up -d

down:
	docker compose down

scan:
	@echo "Running reconnaissance scans..."
	# Placeholder for scan commands

test:
	uv run pytest

lint:
	@echo "Linting YAML and Dockerfiles..."
	# Placeholder for lint commands

clean:
	docker compose down -v
	rm -rf .venv

scan:
	@echo "Running reconnaissance scans..."
	@bash scripts/scan.sh