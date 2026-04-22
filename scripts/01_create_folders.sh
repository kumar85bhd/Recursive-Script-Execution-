#!/usr/bin/env bash
# ================================================================
# scripts/01_create_folders.sh — Create isolated run folder
# Copies template/ into output/<CATEGORY>/<TESTCASE>/<RUN_ID>/
# Idempotent: if dest exists, removes and recreates.
# ================================================================
set -euo pipefail

CATEGORY="$1"
TEST_CASE="$2"
FOLDER_NAME="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logger.sh"

TEMPLATE="${PROJECT_ROOT}/template"
DEST="${RUN_OUTPUT_DIR}"

if [[ ! -d "${TEMPLATE}" ]]; then
    log_error "template/ not found at ${TEMPLATE}"
    exit 1
fi

# Idempotent: clean remove if exists (retry safety)
[[ -d "${DEST}" ]] && rm -rf "${DEST}"

mkdir -p "$(dirname "${DEST}")"
cp -r "${TEMPLATE}" "${DEST}"
log_info "Folder created: ${DEST}"
