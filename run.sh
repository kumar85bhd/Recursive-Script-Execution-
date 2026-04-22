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
mkdir -p "${PROJECT_ROOT}/state"
mkdir -p "${PROJECT_ROOT}/logs"
mkdir -p "${PROJECT_ROOT}/output"

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
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  AGENT 3 — STATE ANALYST: Generating Summary Report"
echo "═══════════════════════════════════════════════════════"

STATE_FILE="${PROJECT_ROOT}/state/progress.csv"
SUMMARY_FILE="${PROJECT_ROOT}/state/summary.csv"

if [[ -f "${STATE_FILE}" ]]; then

    # ── FIX #5: Filter to 'workflow' step only before summarising.
    # This ensures summary reflects the final step outcome, not
    # whichever step happened to be last in the append-only file.
    echo "Category,TestCase,Step,FolderName,Status,Retry,Timestamp,ErrorMsg,Duration" \
        > "${SUMMARY_FILE}"
    tail -n +2 "${STATE_FILE}" \
        | awk -F',' '$3=="workflow" {key=$1","$2; latest[key]=$0}
                     END {for(k in latest) print latest[k]}' \
        >> "${SUMMARY_FILE}"

    # ── Print final report ─────────────────────────────────────
    TOTAL=$(tail -n +2 "${SUMMARY_FILE}" | wc -l | tr -d ' ')
    DONE=$(grep -c ",DONE," "${SUMMARY_FILE}" 2>/dev/null || echo 0)
    FAILED=$(grep -c ",FAILED," "${SUMMARY_FILE}" 2>/dev/null || echo 0)
    PENDING=$(( TOTAL - DONE - FAILED ))

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║           FINAL EXECUTION SUMMARY                ║"
    echo "╠══════════════════════════════════════════════════╣"
    printf  "║  %-44s ║\n" "Total test cases : ${TOTAL}"
    printf  "║  %-44s ║\n" "DONE             : ${DONE}"
    printf  "║  %-44s ║\n" "FAILED           : ${FAILED}"
    printf  "║  %-44s ║\n" "PENDING/STUCK    : ${PENDING}"
    echo "╠══════════════════════════════════════════════════╣"
    printf  "║  %-44s ║\n" "Full log   : logs/master.log"
    printf  "║  %-44s ║\n" "State file : state/progress.csv"
    printf  "║  %-44s ║\n" "Summary    : state/summary.csv"
    echo "╚══════════════════════════════════════════════════╝"

    if [[ "${FAILED}" -gt 0 ]]; then
        echo ""
        echo "── FAILED TEST CASES ───────────────────────────────────"
        grep ",FAILED," "${SUMMARY_FILE}" \
            | awk -F',' '{print "  FAILED: "$1"/"$2
                          " retry="$6" error="$8}'
        echo "────────────────────────────────────────────────────────"
        echo "  To retry failures: bash run.sh --resume"
        echo "  To force full rerun: bash run.sh --no-resume"
    fi
fi

echo ""
echo "Run complete. Results in output/  Summary in state/summary.csv"
