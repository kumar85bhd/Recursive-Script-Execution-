#!/usr/bin/env bash
# scripts/analyze_results.sh

# ── AUTO STATE ANALYST (Agent 3) — always runs after execution ─
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  AGENT 3 — STATE ANALYST: Generating Summary Report"
echo "═══════════════════════════════════════════════════════"

STATE_FILE="${STATE_FILE:-${RUN_ROOT}/state/progress.csv}"
SUMMARY_FILE="${SUMMARY_FILE:-${RUN_ROOT}/state/summary.csv}"

if [[ -f "${STATE_FILE}" ]]; then

    # ── FIX #5: Filter to 'workflow' step only before summarising.
    # This ensures summary reflects the final step outcome, not
    # whichever step happened to be last in the append-only file.
    echo "Category,TestCase,Step,FolderName,Status,Retry,Timestamp,ErrorMsg,Duration" > "${SUMMARY_FILE}"
    tail -n +2 "${STATE_FILE}" | awk -F',' '$3=="workflow" {key=$1","$2; latest[key]=$0} END {for (k in latest) print latest[k]}' >> "${SUMMARY_FILE}"

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
    printf  "║  %-44s ║\n" "State file : state/progress.csv"
    printf  "║  %-44s ║\n" "Summary    : state/summary.csv"
    echo "╚══════════════════════════════════════════════════╝"

    if [[ "${FAILED}" -gt 0 ]]; then
        echo ""
        echo "── FAILED TEST CASES ───────────────────────────────────"
        grep ",FAILED," "${SUMMARY_FILE}" \
            | awk -F',' '{print "  FAILED: "$1"/"$2
                          " retry="$6" error="$8}'
        
        echo ""
        echo "── FAILED TC ENV UPDATES ───────────────────────────────"
        ENV_UPDATE_FILE="${ENV_UPDATE_FILE:-${RUN_ROOT}/state/env_updates.csv}"
        if [[ -f "${ENV_UPDATE_FILE}" ]]; then
            grep ",FAILED," "${SUMMARY_FILE}" | awk -F',' '{print $2}' | while read -r fail_tc; do
                echo "  [${fail_tc}] env updates:"
                updates=$(grep "^${fail_tc}," "${ENV_UPDATE_FILE}" || true)
                if [[ -z "${updates}" ]]; then
                    echo "    -> (No variable overrides tracked)"
                else
                    echo "${updates}" | while read -r line; do
                        fname=$(echo "$line" | cut -d',' -f2)
                        runid=$(echo "$line" | cut -d',' -f3)
                        upds=$(echo "$line" | cut -d',' -f4)
                        echo "    -> ${runid} | ${fname} -> ${upds}"
                    done
                fi
            done
        fi
        
        echo "────────────────────────────────────────────────────────"
        echo "  To retry failures: bash run.sh --resume"
        echo "  To force full rerun: bash run.sh --no-resume"
    fi
fi

echo ""
echo "Run complete. Results in output/  Summary in state/summary.csv"
