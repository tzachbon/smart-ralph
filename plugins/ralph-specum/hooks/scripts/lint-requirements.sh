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

# --- C1: ID & cross-reference integrity ---

# report_malformed <label> <loose-pattern> <strict-pattern>
# Lines matching loose (definition-shaped) but not strict (well-formed) = malformed ID token.
# Strict pattern must account for the "N:" prefix added by grep -n.
report_malformed() {
    local label="$1"
    local loose="$2"
    local strict="$3"
    local hits line
    hits=$(grep -nE "$loose" "$FILE" | grep -vE "$strict")
    [ -z "$hits" ] && return 0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        fail_finding "C1" "malformed $label ID at line ${line%%:*}: ${line#*:}"
    done <<EOF
$hits
EOF
}

report_malformed "US" '^### US-' '^[0-9]+:### US-[0-9]+:'
report_malformed "AC" '^[[:space:]]*- AC-' '^[0-9]+:[[:space:]]*- AC-[0-9]+\.[0-9]+:'
report_malformed "FR" '^\|[[:space:]]*FR-' '^[0-9]+:\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|'
report_malformed "NFR" '^\|[[:space:]]*NFR-' '^[0-9]+:\|[[:space:]]*NFR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|'

# Collect defined IDs (well-formed only; FR-N (retired) counts as defined)
US_IDS=$(grep -E '^### US-[0-9]+:' "$FILE" | sed -E 's/^### (US-[0-9]+):.*/\1/')
AC_IDS=$(grep -E '^[[:space:]]*- AC-[0-9]+\.[0-9]+:' "$FILE" | sed -E 's/^[[:space:]]*- (AC-[0-9]+\.[0-9]+):.*/\1/')
FR_IDS=$(grep -E '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE" | sed -E 's/^\|[[:space:]]*(FR-[0-9]+).*/\1/')
NFR_IDS=$(grep -E '^\|[[:space:]]*NFR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE" | sed -E 's/^\|[[:space:]]*(NFR-[0-9]+).*/\1/')

# Duplicate defined IDs = FAIL
report_duplicates() {
    local ids="$1"
    [ -z "$ids" ] && return 0
    local dup
    for dup in $(echo "$ids" | sort | uniq -d); do
        fail_finding "C1" "duplicate ID defined: $dup"
    done
}
report_duplicates "$US_IDS"
report_duplicates "$AC_IDS"
report_duplicates "$FR_IDS"
report_duplicates "$NFR_IDS"

# FR-table cross-references: dangling AC ref = FAIL; FR row with zero AC refs = FAIL
# (retired rows exempt from the zero-ref rule)
FR_ROWS=$(grep -E '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE")
REFERENCED_ACS=""
while IFS= read -r row; do
    [ -z "$row" ] && continue
    frid=$(echo "$row" | sed -E 's/^\|[[:space:]]*(FR-[0-9]+).*/\1/')
    refs=$(echo "$row" | grep -oE 'AC-[0-9]+\.[0-9]+' | sort -u)
    if [ -z "$refs" ]; then
        if ! echo "$row" | grep -qE '^\|[[:space:]]*FR-[0-9]+[[:space:]]*\(retired\)'; then
            fail_finding "C1" "$frid references no AC-N.N IDs in Acceptance Criteria column"
        fi
        continue
    fi
    for r in $refs; do
        REFERENCED_ACS="$REFERENCED_ACS
$r"
        if ! echo "$AC_IDS" | grep -qx "$r"; then
            fail_finding "C1" "$frid references undefined $r"
        fi
    done
done <<EOF
$FR_ROWS
EOF

# Defined AC referenced by no FR row = WARN
for ac in $AC_IDS; do
    if ! echo "$REFERENCED_ACS" | grep -qx "$ac"; then
        warn_finding "C1" "$ac defined but referenced by no FR row"
    fi
done

# Suspicious ID sequence (gaps without retirement) = WARN
# check_sequence <id-prefix> <newline-list-of-numbers>
check_sequence() {
    local label="$1"
    local nums="$2"
    [ -z "$nums" ] && return 0
    local expected=1 n
    for n in $(echo "$nums" | sort -n | uniq); do
        if [ "$n" -gt "$expected" ]; then
            warn_finding "C1" "suspicious ID sequence: ${label}${expected} missing (gap before ${label}${n})"
        fi
        expected=$((n + 1))
    done
}
check_sequence "US-" "$(echo "$US_IDS" | sed 's/^US-//')"
check_sequence "FR-" "$(echo "$FR_IDS" | sed 's/^FR-//')"
check_sequence "NFR-" "$(echo "$NFR_IDS" | sed 's/^NFR-//')"
if [ -n "$AC_IDS" ]; then
    for s in $(echo "$AC_IDS" | sed -E 's/^AC-([0-9]+)\..*/\1/' | sort -n | uniq); do
        check_sequence "AC-${s}." "$(echo "$AC_IDS" | grep "^AC-${s}\." | sed -E 's/^AC-[0-9]+\.([0-9]+)$/\1/')"
    done
fi

# --- C2: Given/When/Then clause presence ---

# Join each `- AC-N.N:` bullet with its continuation lines (until next list
# item or blank line) into "AC-ID<TAB>full text" lines.
AC_BLOCKS=$(awk '
    function flush() { if (id != "") print id "\t" text }
    /^[[:space:]]*- AC-[0-9]+\.[0-9]+:/ {
        flush()
        id = $0; sub(/^[[:space:]]*- /, "", id); sub(/:.*/, "", id)
        text = $0
        next
    }
    /^[[:space:]]*$/ { flush(); id = ""; next }
    /^[[:space:]]*- / { flush(); id = ""; next }
    { if (id != "") text = text " " $0 }
    END { flush() }
' "$FILE")

while IFS="$(printf '\t')" read -r acid actext; do
    [ -z "$acid" ] && continue
    for clause in Given When Then; do
        if ! echo "$actext" | grep -qw "$clause"; then
            fail_finding "C2" "$acid: missing \"$clause\" clause"
        fi
    done
done <<EOF
$AC_BLOCKS
EOF

# --- C3: MoSCoW priority values (FR table only) ---

# Scope: FR-table rows only (`| FR-N |`); Risks-table Impact column
# (High/Medium/Low) and NFR rows are never scanned. Third table column
# (awk -F'|' field $4) is the Priority cell.
C3_HITS=$(awk -F'|' '
    /^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|/ {
        id = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
        prio = $4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", prio)
        if (prio != "Must" && prio != "Should" && prio != "Could")
            print id "\t" prio
    }
' "$FILE")

while IFS="$(printf '\t')" read -r frid prio; do
    [ -z "$frid" ] && continue
    fail_finding "C3" "$frid: Priority \"$prio\" is not a MoSCoW value (Must/Should/Could)"
done <<EOF
$C3_HITS
EOF

# --- C4: Requirement-language lint ---

# Modal presence (FAIL): each active FR row's Requirement cell (2nd table
# column) must contain an uppercase MUST or SHOULD. Retired rows exempt.
C4_MODAL_HITS=$(awk -F'|' '
    /^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|/ {
        id = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
        if ($3 !~ /MUST/ && $3 !~ /SHOULD/) print id
    }
' "$FILE")
for frid in $C4_MODAL_HITS; do
    fail_finding "C4" "$frid: Requirement text lacks MUST/SHOULD modal"
done

# Banned vague terms (WARN, heuristic -- never FAIL): scoped to FR-table rows
# and AC bullet lines only; case-insensitive whole-word match.
C4_SCOPED=$(grep -nE '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\||^[[:space:]]*- AC-[0-9]+\.[0-9]+:' "$FILE")
if [ -n "$C4_SCOPED" ]; then
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        for term in gracefully seamless robust user-friendly appropriately properly "works correctly"; do
            if echo "${line#*:}" | grep -qiw -- "$term"; then
                warn_finding "C4" "vague term \"$term\" at line ${line%%:*} (heuristic)"
            fi
        done
    done <<EOF
$C4_SCOPED
EOF
fi

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
