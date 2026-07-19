#!/bin/bash
# Requirements Lint Gate for Ralph Specum
# Runs the 8 deterministic checks (C1-C8) against a requirements.md artifact
#
# Usage: lint-requirements.sh <path-to-requirements.md>
#
# Output (stdout, one line per finding, then summary):
#   FAIL|Cn|<message>   - FAIL-class finding for check Cn
#   WARN|Cn|<message>   - WARN-class finding for check Cn
#   CHECK|Cn|PASS       - emitted for each clean check
#   RESULT: <PASS|FAIL> (X FAIL, Y WARN, Z PASS)
#
# Exit codes:
#   0 - no FAIL-class findings (WARNs allowed)
#   1 - one or more FAIL-class findings
#   2 - usage error / file not found / unreadable
#
# NOTE: no `set -e` -- checks must never abort the run; every check reports
# findings and the script always reaches the summary.

usage() {
    echo "Usage: lint-requirements.sh <path-to-requirements.md>" >&2
}

# --- Arg validation ---
FILE="$1"

if [ -z "$FILE" ]; then
    usage
    exit 2
fi

if [ ! -f "$FILE" ] || [ ! -r "$FILE" ]; then
    echo "Error: file not found or unreadable: $FILE" >&2
    usage
    exit 2
fi

# --- Finding state ---
FAIL_COUNT=0
WARN_COUNT=0

# Per-check status: PASS until a finding downgrades it (FAIL > WARN > PASS)
C1_STATUS="PASS"
C2_STATUS="PASS"
C3_STATUS="PASS"
C4_STATUS="PASS"
C5_STATUS="PASS"
C6_STATUS="PASS"
C7_STATUS="PASS"
C8_STATUS="PASS"

# fail_finding <check> <message> - emit FAIL finding, mark check FAIL
fail_finding() {
    local check="$1"
    local msg="$2"
    echo "FAIL|$check|$msg"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    eval "${check}_STATUS=FAIL"
}

# warn_finding <check> <message> - emit WARN finding, mark check WARN (never overrides FAIL)
warn_finding() {
    local check="$1"
    local msg="$2"
    echo "WARN|$check|$msg"
    WARN_COUNT=$((WARN_COUNT + 1))
    local current
    eval "current=\$${check}_STATUS"
    if [ "$current" != "FAIL" ]; then
        eval "${check}_STATUS=WARN"
    fi
}

# --- Checks C1-C8 (implemented in subsequent tasks) ---

# --- Summary ---
PASS_COUNT=0
for n in 1 2 3 4 5 6 7 8; do
    eval "status=\$C${n}_STATUS"
    if [ "$status" = "PASS" ]; then
        echo "CHECK|C${n}|PASS"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
done

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "RESULT: FAIL ($FAIL_COUNT FAIL, $WARN_COUNT WARN, $PASS_COUNT PASS)"
    exit 1
else
    echo "RESULT: PASS ($FAIL_COUNT FAIL, $WARN_COUNT WARN, $PASS_COUNT PASS)"
    exit 0
fi
