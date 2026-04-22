#!/usr/bin/env bash
# ================================================================
# scripts/run_testcase.sh
# Retry loop for a single test case.
# RUN_ID is set ONCE per retry — never recomputed inside steps.
# Steps must be idempotent (safe to re-run).
# ================================================================
set -euo pipefail

CATEGORY="$1"
TEST_CASE="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export CATEGORY TEST_CASE

source "${SCRIPT_DIR}/utils/logger.sh"
source "${SCRIPT_DIR}/utils/state_manager.sh"

MAX_RETRIES=${MAX_RETRIES:-2}
RETRY_ENABLED=${RETRY_ENABLED:-yes}

# ── Resolve Folder_name from simulation.txt ─────────────────────
SIM_FILE="${PROJECT_ROOT}/input_xls/${CATEGORY}/simulation.txt"
FOLDER_NAME=$(awk -F',' -v tc="${TEST_CASE}" \
    'NR>1 && $1==tc {gsub(/ /,"",$2); print $2; exit}' "${SIM_FILE}")

if [[ -z "${FOLDER_NAME:-}" ]]; then
    log_error "Folder_name not found for ${CATEGORY}/${TEST_CASE}"
    exit 1
fi
export FOLDER_NAME

STEPS=("01_create_folders.sh" "02_populate_env.py" \
       "03_run_simulation.sh" "04_workflow.py")
STEP_NAMES=("create_folders" "populate_env" "run_simulation" "workflow")

retry=0
while [[ ${retry} -le ${MAX_RETRIES} ]]; do

    # ── FIX #4: RUN_ID set ONCE here, exported, never recomputed ──
    export BASE_RUN_DATE="$(date +%d%m%Y)"
    export RETRY_COUNT=${retry}
    export RUN_ID="${BASE_RUN_DATE}_${retry}"
    export RUN_OUTPUT_DIR="${PROJECT_ROOT}/output/${CATEGORY}/${TEST_CASE}/${RUN_ID}"

    log_sep
    log_info "══ ${CATEGORY}/${TEST_CASE} | RUN_ID=${RUN_ID} | retry=${retry}/${MAX_RETRIES} ══"

    all_ok=true
    failed_step=""

    for i in "${!STEPS[@]}"; do
        step_name="${STEP_NAMES[$i]}"
        cmd="${STEPS[$i]}"

        # Resume: skip steps already DONE for this retry
        if [[ "${RESUME:-yes}" == "yes" ]]; then
            status=$(state_get "${CATEGORY}" "${TEST_CASE}" "${step_name}" "${retry}")
            if [[ "${status}" == "DONE" ]]; then
                log_info "SKIP (DONE): ${step_name} retry=${retry}"
                continue
            fi
        fi

        log_info "STEP $((i+1))/4: ${step_name}"
        start_ts=$(date +%s)

        state_set "${CATEGORY}" "${TEST_CASE}" "${step_name}" \
                  "${FOLDER_NAME}" "IN_PROGRESS" "${retry}" "" "0"

        # ── FIX #3: No 2>> redirection — logger handles all output ─
        set +e
        if [[ "${cmd}" == *.sh ]]; then
            bash "${SCRIPT_DIR}/${cmd}" "${CATEGORY}" "${TEST_CASE}" "${FOLDER_NAME}"
        else
            python3 "${SCRIPT_DIR}/${cmd}" "${CATEGORY}" "${TEST_CASE}" "${FOLDER_NAME}"
        fi
        exit_code=$?
        set -e

        end_ts=$(date +%s)
        duration=$((end_ts - start_ts))

        if [[ ${exit_code} -ne 0 ]]; then
            errmsg="exit=${exit_code} log=logs/${CATEGORY}/${TEST_CASE}/retry_${retry}.log"
            state_set "${CATEGORY}" "${TEST_CASE}" "${step_name}" \
                      "${FOLDER_NAME}" "FAILED" "${retry}" "${errmsg}" "${duration}"
            log_error "STEP FAILED: ${step_name} (${duration}s)"
            all_ok=false
            failed_step="${step_name}"
            break
        else
            state_set "${CATEGORY}" "${TEST_CASE}" "${step_name}" \
                      "${FOLDER_NAME}" "DONE" "${retry}" "" "${duration}"
            log_info "STEP DONE: ${step_name} (${duration}s)"
        fi
    done

    if [[ "${all_ok}" == true ]]; then
        log_info "✓ SUCCESS: ${CATEGORY}/${TEST_CASE} RUN_ID=${RUN_ID}"
        break
    fi

    if [[ "${RETRY_ENABLED}" != "yes" || ${retry} -ge ${MAX_RETRIES} ]]; then
        log_error "✗ RETRIES EXHAUSTED: ${CATEGORY}/${TEST_CASE} failed at ${failed_step}"
        break
    fi

    retry=$((retry + 1))
    log_warn "Retrying ${CATEGORY}/${TEST_CASE} (attempt ${retry}/${MAX_RETRIES})..."
    sleep 2
done
