SHELL := /usr/bin/env bash

MODEL ?= K020-tau-not-estimated-sel20c-f10-ndpen-weak
PROGRAM_PATH ?= /home/mfcl/mfclo64

.PHONY: help validate run

help:
	@printf '%s\n' \
	  'BET 2026 final-exploration commands' \
	  '' \
	  'make validate' \
	  '  Validate all 28 frozen input folders without running MFCL.' \
	  '' \
	  'make run MODEL=K015-tau-estimated PROGRAM_PATH=/path/to/mfclo64' \
	  '  Run one selected exploration.' \
	  '' \
	  'Robust candidates include F10 logistic, F1-F3 four-node, and F33 logistic/non-decreasing sensitivities.'

validate:
	@bash scripts/validate-inputs.sh

run:
	@MODEL='$(MODEL)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	bash run.sh
