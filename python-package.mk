# -------------------------------------------------------------------
# Shared Makefile for AIDu Python packages
#
# Usage:
#
#   PACKAGE=aidu-ai-actor
#   EXAMPLE=tutor_actor
#
#   include ../aidu-dev-tools/python-package.mk
#
# -------------------------------------------------------------------

UV=uv
FIND=find
DEBUG_TRUE_VALUES=1 True true TRUE yes YES y Y on ON
DEBUG ?= False
# Prefer explicit AIDU_DEBUG (set by package Makefiles) and fall back to DEBUG.
AIDU_DEBUG ?= $(if $(filter $(DEBUG_TRUE_VALUES),$(DEBUG)),1,0)
RUN_DEBUG=$(if $(filter $(DEBUG_TRUE_VALUES),$(AIDU_DEBUG) $(DEBUG)),True,False)
RUN_AIDU_DEBUG=$(if $(filter $(DEBUG_TRUE_VALUES),$(AIDU_DEBUG) $(DEBUG)),1,0)

.PHONY: help install clean wipe run run-example smoke test lint format check-format pre-commit-install pre-commit-run jupyter

help:                                     ## Show this help
	@grep -h "##" $(MAKEFILE_LIST) | grep -v grep | sed -e "s/\$$//" -e "s/##//"

AIDU_DEV_TOOLS_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
DEV_ROOT ?= $(AIDU_DEV_TOOLS_DIR)
include $(DEV_ROOT)/.codex/codex-utils.mk


# -------------------------------------------------------------------
# Install
# -------------------------------------------------------------------

install:                                  ## Install dependencies
	@echo "Installing dependencies"
	@$(UV) sync

	@echo "Upgrading pip"
	@$(UV) run python -m ensurepip --upgrade

# -------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------

clean:                                    ## Clean temporary and cache files
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf .venv
	rm -rf web/node_modules

	$(FIND) . -type f -name '*~' -delete
	$(FIND) . -type f -name '*.pyc' -delete
	$(FIND) . -type d -name '__pycache__' -delete
	$(FIND) . -type d -name 'dist' -prune -exec rm -rf {} +

wipe: clean                               ## Delete all uv-related files
	@echo "Removing uv.lock"
	rm -f uv.lock

# -------------------------------------------------------------------
# Run examples
# -------------------------------------------------------------------

# Packages can set RUN_HOOK before including this file to customize `make run`.
RUN_HOOK ?= run-example

run: $(RUN_HOOK)                          ## Run an example (e.g. make run EXAMPLE=tutor_agent DEBUG=True)

run-example:
ifndef EXAMPLE
	@echo "No EXAMPLE specified. Usage: make run EXAMPLE=example_name"
else
	@echo "Running example: $(EXAMPLE)"
	@AIDU_DEBUG=$(RUN_AIDU_DEBUG) $(UV) run python -m $(EXAMPLE)
endif

# -------------------------------------------------------------------
# Smoke Tests
# -------------------------------------------------------------------

smoke:                                    ## Run all smoke modules
ifndef SMOKE_MODULES
	@echo "No SMOKE_MODULES defined"
else
	@for module in $(SMOKE_MODULES); do \
		echo "Running $$module"; \
		$(UV) run python -m $$module || exit 1; \
	done
endif

# -------------------------------------------------------------------
# Embedded Frontend
# -------------------------------------------------------------------

web-build:                                   ## Build the embedded frontend
	@echo "Building embedded frontend"
	@cd web && npm install && npm run build
	@mkdir -p $(WEB_DIST_DIR)
	@cp -r web/dist/* $(WEB_DIST_DIR)


# -------------------------------------------------------------------
# Testing
# -------------------------------------------------------------------

test:                                     ## Run all tests
	$(UV) run pytest

# -------------------------------------------------------------------
# Linting / Formatting
# -------------------------------------------------------------------

lint:                                     ## Run ruff linting
	$(UV) run ruff check src tests || true

format:                                   ## Format code
	$(UV) run black .
	$(UV) run ruff format .


check-format:                             ## Check formatting
	$(UV) run black --check .
	$(UV) run ruff check .

# -------------------------------------------------------------------
# Pre-commit
# -------------------------------------------------------------------

pre-commit-install:                       ## Install pre-commit hooks
	$(UV) run pip install pre-commit
	$(UV) run pre-commit install

pre-commit-run:                           ## Run pre-commit checks
	$(UV) run pre-commit run --all-files

# -------------------------------------------------------------------
# Jupyter
# -------------------------------------------------------------------

jupyter:                                  ## Start Jupyter Lab
	@if [ ! -d ".venv" ]; then uv venv; fi
	uv pip install jupyter
	uv run jupyter lab

# -------------------------------------------------------------------
# Publishing
# -------------------------------------------------------------------
build:                                    ## Build package artifacts
	-$(MAKE) web.build

	rm -rf dist
	$(UV) build

publish: build                            ## Publish the package to PyPI
	@echo "Publishing package..."
	@. ~/.env && uv publish --token "$$PYPI_TOKEN"
