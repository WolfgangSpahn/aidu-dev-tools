# -------------------------------------------------------------------
# Codex prompt macros
#
# Usage from project Makefile:
#
#   include $(HOME)/Projects/Python/AIDu_NG/aidu-dev-tools/codex.mk
#
# Examples:
#
#   make codex-search FEATURE=applet-tool-call
#   make codex-implement FEATURE=applet-tool-call SLICE=01
#   make codex-debug FEATURE=applet-tool-call ERROR=/tmp/error.log
# -------------------------------------------------------------------

DEV_ROOT ?= $(HOME)/Projects/Python/AIDu_NG/aidu-dev-tools

CODEX_PROMPTS ?= $(DEV_ROOT)/.codex/prompts
CODEX_FEATURES ?= $(DEV_ROOT)/.codex/features
CODEX_PLANS ?= $(DEV_ROOT)/.codex/plans
CODEX_SLICES ?= $(DEV_ROOT)/.codex/slices
CODEX_SCRIPTS ?= $(DEV_ROOT)/.codex/scripts

PYTHON ?= python

.PHONY: codex-search codex-implement codex-debug codex-review codex-check-feature

codex-check-feature:
	@test -n "$(FEATURE)" || (echo "FEATURE is required, e.g. make codex-search FEATURE=applet-tool-call" >&2; exit 1)

codex-search: codex-check-feature
	@$(PYTHON) $(CODEX_SCRIPTS)/render_codex_prompt.py \
		$(CODEX_PROMPTS)/search-change-points.md \
		--feature $(CODEX_FEATURES)/$(FEATURE).md

codex-implement: codex-check-feature
	@test -n "$(SLICE)" || (echo "SLICE is required, e.g. make codex-implement FEATURE=applet-tool-call SLICE=01" >&2; exit 1)
	@$(PYTHON) $(CODEX_SCRIPTS)/render_codex_prompt.py \
		$(CODEX_PROMPTS)/implement-slice.md \
		--feature $(CODEX_FEATURES)/$(FEATURE).md \
		--plan $(CODEX_PLANS)/$(FEATURE).plan.md \
		--slice $(CODEX_SLICES)/$(FEATURE)-$(SLICE).md

codex-debug: codex-check-feature
	@test -n "$(ERROR)" || (echo "ERROR is required, e.g. make codex-debug FEATURE=applet-tool-call ERROR=/tmp/error.log" >&2; exit 1)
	@$(PYTHON) $(CODEX_SCRIPTS)/render_codex_prompt.py \
		$(CODEX_PROMPTS)/debug-failure.md \
		--feature $(CODEX_FEATURES)/$(FEATURE).md \
		--plan $(CODEX_PLANS)/$(FEATURE).plan.md \
		--error $(ERROR)

codex-review: codex-check-feature
	@test -n "$(DIFF)" || (echo "DIFF is required, e.g. make codex-review FEATURE=applet-tool-call DIFF=/tmp/change.diff" >&2; exit 1)
	@$(PYTHON) $(CODEX_SCRIPTS)/render_codex_prompt.py \
		$(CODEX_PROMPTS)/review-diff.md \
		--feature $(CODEX_FEATURES)/$(FEATURE).md \
		--plan $(CODEX_PLANS)/$(FEATURE).plan.md \
		--diff $(DIFF)
