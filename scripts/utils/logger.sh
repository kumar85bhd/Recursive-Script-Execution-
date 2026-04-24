#!/usr/bin/env bash
# ================================================================
# scripts/utils/logger.sh — Centralised Logger
# Source this file in every script. Do not execute directly.
#
# Writes to:
#   logs/master.log                               always
#   logs/<CATEGORY>/<TESTCASE>/retry_<N>.log      when context set
# ================================================================

LOGS_ROOT="${RUN_ROOT:-${PROJECT_ROOT}}/logs"
MASTER_LOG="${LOGS_ROOT}/master.log"
mkdir -p "${LOGS_ROOT}"

_log() {
    local level="$1" msg="$2"
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[${ts}] [${level}] [${CATEGORY:-GLOBAL}] [${TEST_CASE:--}] ${msg}"
    echo "${line}"
    echo "${line}" >> "${MASTER_LOG}"
    if [[ -n "${CATEGORY:-}" && -n "${TEST_CASE:-}" && -n "${RETRY_COUNT:-}" ]]; then
        local tc_log="${LOGS_ROOT}/${CATEGORY}/${TEST_CASE}/retry_${RETRY_COUNT}.log"
        mkdir -p "$(dirname "${tc_log}")"
        echo "${line}" >> "${tc_log}"
    fi
}

log_info()  { _log 'INFO ' "$1"; }
log_warn()  { _log 'WARN ' "$1"; }
log_error() { _log 'ERROR' "$1"; }
log_sep()   { _log '-----' '────────────────────────────────────────'; }
