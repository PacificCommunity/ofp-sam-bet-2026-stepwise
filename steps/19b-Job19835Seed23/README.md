# 19b Previous Diagnostic: selected jitter seed 23

Reproduce Job 19835 by promoting the best-objective converged Job 19325 jitter fit.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/19b-Job19835Seed23/model` |
| Status | Ready to reproduce the previous Diagnostic Job 19835 on Suva. |

## Changes

| # | Change |
| --- | --- |
| 1 | All scientific inputs and MFCL controls are unchanged from Step 19a. |
| 2 | The only fitting-path change is the exact CV=0.1 seed-23 initialization at Phases 1, 2 and 5. |
| 3 | Seed 23 was selected by minimum objective among converged jitters, not by depletion. |

## Inputs

| File | Source / note |
| --- | --- |
| `.* / mfcl.cfg` | Byte-identical Step 19a scientific inputs |
| `doitall.sh` | Exact public Job 19835 reproducible seed-23 recipe |
| `seed23-selection-audit.csv` | Selection rule and archived fit statistics |

## Controls

| # | Control |
| --- | --- |
| 1 | Job 19835 objective 89054.3397838085; maximum gradient 9.2968286e-05. |
| 2 | This is a historical comparison branch. Step 20 continues from ordinary-makepar Step 19a. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
