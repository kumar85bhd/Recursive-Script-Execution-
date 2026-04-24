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

# ── Parse all env files ─────────────────────────────────
parse_env_file() {
    local file="$1"

    while IFS= read -r line; do
        line="$(echo "$line" | xargs)" # trim
        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi

        if [[ "$line" == export*=* ]]; then
            key="$(echo "$line" | cut -d'=' -f1 | sed 's/^export *//')"
            val="$(echo "$line" | cut -d'=' -f2-)"
            export "$key=$val"
        elif [[ "$line" == setenv* ]]; then
            # setenv KEY "VAL"
            key="$(echo "$line" | awk '{print $2}')"
            val="$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}' | sed 's/ $//' | sed 's/^"//' | sed 's/"$//')"
            export "$key=$val"
        elif [[ "$line" == set*=* ]]; then
            # set KEY = "VAL"
            key="$(echo "$line" | awk '{print $2}')"
            val="$(echo "$line" | cut -d'=' -f2- | awk '{for(i=1;i<=NF;i++) printf "%s ", $i}' | sed 's/ $//' | sed 's/^"//' | sed 's/"$//')"
            export "$key=$val"
        elif [[ "$line" == *=* ]]; then
            # KEY=VAL
            key="$(echo "$line" | cut -d'=' -f1)"
            val="$(echo "$line" | cut -d'=' -f2-)"
            export "$key=$val"
        fi
    done < "$file"
}

# Dynamically discover all env files
ENV_BASE_PATH="${RUN_OUTPUT_DIR}"

while IFS= read -r env_file; do
    parse_env_file "$env_file"
done < <(find "$ENV_BASE_PATH" -type f -name "env.*")

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
