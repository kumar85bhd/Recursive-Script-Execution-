#!/usr/bin/env bash
# ================================================================
# run.sh — Single Entry Point for RTL Workflow Automation
#
# Usage:
#   bash run.sh                               run all, sequential
#   bash run.sh --parallel                    run all, parallel
#   bash run.sh --category IO                 one category only
#   bash run.sh --category IO --parallel      one category, parallel
#   bash run.sh --category IO --testcase IO_1 one test case only
#   bash run.sh --no-resume                   force re-run all
#   bash run.sh --resume                      skip DONE steps (default)
# ================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="${SCRIPT_DIR}"

# Source config (sets all defaults)
source "${PROJECT_ROOT}/config/run_config.sh"

# ── Parse CLI arguments (override config) ──────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --parallel)     PARALLEL="yes" ;;
        --no-parallel)  PARALLEL="no" ;;
        --resume)       RESUME="yes" ;;
        --no-resume)    RESUME="no" ;;
        --category)     RUN_MODE="category"; TARGET_CAT="$2"; shift ;;
        --testcase)     RUN_MODE="testcase"; TARGET_TC="$2"; shift ;;
        --max-parallel) MAX_PARALLEL="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done
[[ -n "${TARGET_TC:-}" ]] && RUN_MODE="testcase"

export PARALLEL RESUME RUN_MODE TARGET_CAT TARGET_TC MAX_PARALLEL RETRY_ENABLED MAX_RETRIES

# ── FIX #2: Ensure all runtime directories exist before any script runs
mkdir -p "${PROJECT_ROOT}/logs"
mkdir -p "${PROJECT_ROOT}/state"
mkdir -p "${PROJECT_ROOT}/output"

STATE_FILE="${PROJECT_ROOT}/state/progress.csv"
export STATE_FILE
if [[ ! -f "$STATE_FILE" ]]; then
  echo "Category,TestCase,Step,FolderName,Status,Retry,Timestamp,ErrorMsg,Duration" > "$STATE_FILE"
fi

ENV_UPDATE_FILE="${PROJECT_ROOT}/state/env_updates.csv"
export ENV_UPDATE_FILE
if [[ ! -f "$ENV_UPDATE_FILE" ]]; then
  echo "TestCase,FileName,Updates" > "$ENV_UPDATE_FILE"
fi

# ── Print run banner ───────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║        RTL WORKFLOW AUTOMATION                   ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Mode        : ${RUN_MODE}"
echo "║  Category    : ${TARGET_CAT:-ALL}"
echo "║  TestCase    : ${TARGET_TC:-ALL}"
echo "║  Parallel    : ${PARALLEL}"
echo "║  Resume      : ${RESUME}"
echo "║  Max Retries : ${MAX_RETRIES}"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Run orchestrator (Agent 2: Executor) ───────────────────────
bash "${PROJECT_ROOT}/scripts/orchestrator.sh"

# ── AUTO STATE ANALYST (Agent 3) — always runs after execution ─
bash "${PROJECT_ROOT}/scripts/analyze_results.sh"
