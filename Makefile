SHELL := /usr/bin/env bash

MODEL ?= K015-tau-estimated
PROGRAM_PATH ?= /home/mfcl/mfclo64

.PHONY: help validate run

help:
	@printf '%s\n' \
	  'BET 2026 final-exploration commands' \
	  '' \
	  'make validate' \
	  '  Validate all 12 frozen input folders without running MFCL.' \
	  '' \
	  'make run MODEL=K015-tau-estimated PROGRAM_PATH=/path/to/mfclo64' \
	  '  Run one selected exploration.' \
	  '' \
	  'MODEL format: K{005,010,015,020,025,030}-tau-{estimated,not-estimated}'

validate:
	@bash scripts/validate-inputs.sh

run:
	@MODEL='$(MODEL)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	bash run.sh
