#!/usr/bin/env bash
# ================================================================
# scripts/utils/state_manager.sh — State Manager
#
# STATE FILE: state/progress.csv
# Schema: Category,TestCase,Step,FolderName,Status,Retry,
#         Timestamp,ErrorMsg,Duration
#
# MANDATORY: all writes use flock — parallel-safe.
# DO NOT MODIFY THIS FILE.
# ================================================================

STATE_FILE="${PROJECT_ROOT}/state/progress.csv"

state_init() {
    mkdir -p "${PROJECT_ROOT}/state"
    if [[ ! -f "${STATE_FILE}" ]]; then
        echo 'Category,TestCase,Step,FolderName,Status,Retry,Timestamp,ErrorMsg,Duration' \
             > "${STATE_FILE}"
    fi
}

state_set() {
    local cat="$1" tc="$2" step="$3" folder="$4" status="$5"
    local retry="${6:-0}" errmsg="${7:-}" duration="${8:-0}"
    local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
    local row="${cat},${tc},${step},${folder},${status},${retry},${ts},${errmsg},${duration}"
    (
        exec 200>"${STATE_FILE}.lock"
        flock 200
        echo "${row}" >> "${STATE_FILE}"
        flock -u 200
    )
}

state_get() {
    [[ ! -f "${STATE_FILE}" ]] && { echo ""; return; }
    local cat="$1" tc="$2" step="$3" retry="${4:-0}"
    grep "^${cat},${tc},${step},.*,.*,${retry}," "${STATE_FILE}" 2>/dev/null \
        | tail -1 | cut -d',' -f5 || echo ''
}

state_is_done() {
    [[ "$(state_get "$1" "$2" "$3" "${4:-0}")" == 'DONE' ]]
}

state_dump_pending() {
    grep -v ',DONE,' "${STATE_FILE}" | grep -v '^Category' || echo '(none pending)'
}
