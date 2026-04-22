#!/usr/bin/env bash
# ================================================================
# scripts/orchestrator.sh
# Reads master.txt, loops categories and test cases.
# Delegates per-testcase execution to run_testcase.sh.
# DO NOT call directly.
# ================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logger.sh"
source "${SCRIPT_DIR}/utils/state_manager.sh"

MASTER_FILE="${PROJECT_ROOT}/input_xls/master.txt"
state_init

# ── Read unique categories from master.txt ──────────────────────
declare -a CATEGORIES=()
while IFS=',' read -r cat _item; do
    [[ "${cat}" == "Category" ]] && continue
    cat="$(echo "${cat}" | tr -d ' ')"
    if ! printf '%s\n' "${CATEGORIES[@]:-}" | grep -qx "${cat}"; then
        CATEGORIES+=("${cat}")
    fi
done < "${MASTER_FILE}"

log_info "Categories: ${CATEGORIES[*]}"

# ── Scope to target if category or testcase mode ─────────────────
if [[ "${RUN_MODE}" == "category" || "${RUN_MODE}" == "testcase" ]]; then
    CATEGORIES=("${TARGET_CAT}")
fi

run_category() {
    local category="$1"
    local sim_file="${PROJECT_ROOT}/input_xls/${category}/simulation.txt"

    [[ ! -f "${sim_file}" ]] && { log_error "Not found: ${sim_file}"; return 1; }

    log_sep
    log_info "┌── CATEGORY: ${category}"

    declare -a TEST_CASES=()
    while IFS=',' read -r name _rest; do
        [[ "${name}" == "Name" ]] && continue
        name="$(echo "${name}" | tr -d ' ')"
        [[ "${RUN_MODE}" == "testcase" && "${name}" != "${TARGET_TC}" ]] && continue
        TEST_CASES+=("${name}")
    done < "${sim_file}"

    if [[ ${#TEST_CASES[@]} -eq 0 ]]; then
        log_warn "No test cases matched for ${category}"
        return 0
    fi

    if [[ "${PARALLEL:-no}" == "yes" ]]; then
        log_info "Mode: PARALLEL (max ${MAX_PARALLEL} jobs)"
        declare -a PIDS=()
        for tc in "${TEST_CASES[@]}"; do
            while [[ $(jobs -r | wc -l) -ge "${MAX_PARALLEL}" ]]; do sleep 2; done
            bash "${SCRIPT_DIR}/run_testcase.sh" "${category}" "${tc}" &
            PIDS+=($!)
            log_info "Launched: ${category}/${tc} PID=$!"
        done
        for pid in "${PIDS[@]}"; do
            wait "${pid}" || log_warn "PID ${pid} non-zero exit"
        done
    else
        log_info "Mode: SEQUENTIAL"
        for tc in "${TEST_CASES[@]}"; do
            bash "${SCRIPT_DIR}/run_testcase.sh" "${category}" "${tc}" || true
        done
    fi

    log_info "└── DONE: ${category}"
}

if [[ "${PARALLEL:-no}" == "yes" && "${RUN_MODE}" == "all" ]]; then
    declare -a CAT_PIDS=()
    for cat in "${CATEGORIES[@]}"; do
        run_category "${cat}" & CAT_PIDS+=($!)
    done
    for pid in "${CAT_PIDS[@]}"; do wait "${pid}" || true; done
else
    for cat in "${CATEGORIES[@]}"; do run_category "${cat}"; done
fi

log_info "Orchestrator complete."
