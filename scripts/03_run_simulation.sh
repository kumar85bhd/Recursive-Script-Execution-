#!/usr/bin/env bash
# ================================================================
# scripts/03_run_simulation.sh — Pluggable EDA Execution Step
#
# TO INTEGRATE YOUR TOOL:
#   Find block: # === YOUR COMMAND HERE ===
#   Replace ONLY that block with your EDA command.
#   All env vars are already exported as shell variables.
#
# RUN_ID is immutable — do NOT recompute it here.
# ================================================================
set -euo pipefail

CATEGORY="$1"
TEST_CASE="$2"
FOLDER_NAME="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logger.sh"

BASE_PATH="${RUN_OUTPUT_DIR}"

# ── Source all env files ─────────────────────────────────────────
# This exports every KEY=VALUE as a shell variable.
set -o allexport
source "${BASE_PATH}/common/env.common"
source "${BASE_PATH}/simulation/env.simulation"
source "${BASE_PATH}/back_ann/env.back_ann"
set +o allexport

log_info "Env loaded: DESIGN_PATH=${DESIGN_PATH:-UNSET} DSIM_PATH=${DSIM_PATH:-UNSET}"

# ================================================================
# === YOUR COMMAND HERE ==========================================
#
# Available shell variables at this point:
#   ${DESIGN_PATH}     from simulation.txt → design_path
#   ${DSIM_PATH}       from simulation.txt → dsim_path
#   ${val1}            from back_ann.txt
#   ${val2}            from back_ann.txt
#   ${val3}            from back_ann.txt
#   ${RUN_OUTPUT_DIR}  isolated output folder for this run
#   ${RUN_ID}          e.g. 22042026_0
#   ${CATEGORY}        e.g. IO
#   ${TEST_CASE}       e.g. IO_1
#   Plus all Var_name values from common.txt
#
# Integration examples:
#
#   Option A — Call your bash script:
#     bash /path/to/run_testbench.sh
#
#   Option B — EDA tool directly:
#     vcs -full64 -sverilog "${DESIGN_PATH}" -o simv && ./simv
#
#   Option C — Makefile:
#     make -C "${BASE_PATH}" simulate
#
# ================================================================

log_info "Step 3 placeholder — add your EDA command above"
SIMULATION_EXIT_CODE=0    # Remove this line when integrating real command

# ── End of pluggable section ─────────────────────────────────────

if [[ "${SIMULATION_EXIT_CODE:-0}" -ne 0 ]]; then
    log_error "Simulation failed: exit ${SIMULATION_EXIT_CODE}"
    exit "${SIMULATION_EXIT_CODE}"
fi
log_info "Step 3 complete"
