# RTL Workflow Automation — Claude Code Instructions

## What This System Does
Automates RTL testcase execution end-to-end.
One command. Unattended overnight. Produces full results and summary.

---

## How Claude Code Agents Work Here

There is NO agent registration in Claude Code.
CLAUDE.md IS the agent definition.
Claude Code reads this file automatically on every session start.
The three agents below are cognitive roles played by one Claude instance.
They are NOT separate processes or registered services.

---

## Entry Point — ALWAYS use this

    bash run.sh [options]

    --parallel              run test cases in parallel
    --category IO           run only the IO category
    --testcase IO_1         run only IO_1 (also set --category)
    --no-resume             force full re-run, ignore state
    --resume                skip DONE steps (default)

NEVER call scripts/ directly except for isolated debugging.

---

## Agent 1 — Planner

Role: reads inputs, builds execution plan before any runs start.
Reads:
  - input_xls/master.txt              (categories and test cases)
  - config/run_config.sh              (parallel, retry, scope settings)
  - input_xls/<CAT>/simulation.txt    (test case names per category)
Produces: mental execution plan — categories x test cases x retry budget.
When invoked: automatically at start of every run.sh call.

---

## Agent 2 — Executor

Role: runs the 4-step pipeline for every test case, manages retries.
Entry: orchestrator.sh → run_testcase.sh → Steps 01 to 04.
Rules:
  - Execution unit is the TestCase
  - Steps run strictly in order: 01 → 02 → 03 → 04
  - Retry is sequential per testcase (NEVER parallel retries)
  - A testcase MUST NEVER run in parallel with itself
  - RUN_ID is set ONCE per retry at top of loop — never recomputed
  - RUN_ID format: DDMMYYYY_<retryN>  e.g. 22042026_0, 22042026_1
  - Output folder: output/<CATEGORY>/<TESTCASE>/<RUN_ID>/
  - Steps must be idempotent — safe to re-run without corrupting output
When invoked: automatically after Planner.

---

## Agent 3 — State Analyst

Role: reads state after all runs, classifies outcomes, generates report.
Reads: state/progress.csv, logs/
Produces: state/summary.csv, terminal report, failure classification.
When invoked: AUTOMATICALLY at end of every run.sh call — no manual trigger.

Failure classification:
  Config fix  — wrong value in run_config.sh or input_xls/
  Script fix  — bug in scripts/03_run_simulation.sh (EDA command)
  Input fix   — missing row or bad column in simulation.txt / back_ann.txt
  Env fix     — missing or empty env file after populate step

---

## Input File Structure

input_xls/master.txt              Category,item_description
input_xls/<CAT>/common.txt        Var_name,Value  (all TCs in category)
input_xls/<CAT>/simulation.txt    Name,Folder_name,design_path,dsim_path
input_xls/<CAT>/back_ann.txt      Name,val1,val2,val3

Matching rules:
  simulation.txt drives the loop (one row = one test case).
  back_ann.txt matched to simulation.txt via Name column.
  common.txt written identically to every test case in the category.

---

## State Rules (NON-NEGOTIABLE)

  - state/progress.csv is append-only — never delete or edit entries
  - Each row = one execution attempt of one step
  - Latest row per Category+TestCase+Step+Retry = current status
  - ALL writes must use flock (see state_manager.sh)
  - Never rely on chat memory — always read from files
  - RUN_ID is immutable per retry — never recompute inside steps

---

## Context Reset Protocol

If context window resets or session is interrupted:
  1. cat state/progress.csv
  2. cat state/summary.csv
  3. bash run.sh --resume
     Skips all DONE steps. Retries FAILED. Continues PENDING.
     No completed work is ever lost.

---

## Step 3 — EDA Tool Integration

Edit ONLY the marked block in scripts/03_run_simulation.sh:
     # === YOUR COMMAND HERE ===
All env vars (DESIGN_PATH, DSIM_PATH, val1, val2, val3, plus all
Var_name values from common.txt) are already exported at that point.

---

## What Claude May Modify

  config/run_config.sh               (settings)
  input_xls/*                        (data files)
  scripts/03_run_simulation.sh       (EDA command block only)
  scripts/02_populate_env.py         (adding new env keys)
  scripts/04_workflow.py             (output formatting)
  scripts/utils/env_utils.py         (shared utilities)

## What Claude MUST NOT Modify

  scripts/utils/state_manager.sh     (state safety — flock logic)
  scripts/run_testcase.sh            (retry sequencing)
  scripts/orchestrator.sh            (loop logic)
  run.sh                             (entry point contract)
  The flock block in state_manager   (never remove locks)

---

## Debugging Protocol

  1. grep FAILED state/progress.csv
  2. cat logs/<CATEGORY>/<TESTCASE>/retry_<N>.log
  3. Classify: Config | Script | Input | Env
  4. Fix in the allowed file (see above)
  5. bash run.sh --resume

DO NOT rerun blindly. Always classify the failure first.
