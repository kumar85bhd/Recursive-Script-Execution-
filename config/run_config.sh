#!/usr/bin/env bash
# ================================================================
# config/run_config.sh — Execution Configuration
# SOURCE this file — do not execute directly.
# Claude Code: modify settings here, nowhere else.
# ================================================================

# ── Parallel control ───────────────────────────────────────────
# WARNING: only enable if your EDA tool supports concurrent runs.
PARALLEL="no"
MAX_PARALLEL=4

# ── Retry control ──────────────────────────────────────────────
# Each retry is sequential (never parallel). Each retry =
# new RUN_ID = completely isolated output folder.
RETRY_ENABLED="yes"
MAX_RETRIES=2

# ── Execution scope ────────────────────────────────────────────
# Overridden by CLI arguments at runtime.
RUN_MODE="all"    # all | category | testcase
TARGET_CAT=""
TARGET_TC=""

# ── Resume behaviour ───────────────────────────────────────────
# yes = skip steps already DONE in state/progress.csv
# no  = full re-run regardless of state
RESUME="yes"
