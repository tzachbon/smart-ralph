#!/bin/bash
# Requirements Lint Gate for Ralph Specum
# Runs the 8 deterministic checks (C1-C8) against a requirements.md artifact
#
# Usage: lint-requirements.sh <path-to-requirements.md>
#
# Output (stdout, one line per finding, then summary):
#   FAIL|Cn|<message>   - FAIL-class finding for check Cn
#   WARN|Cn|<message>   - WARN-class finding for check Cn
#   CHECK|Cn|<STATUS>   - one canonical status line per check (PASS/WARN/FAIL)
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

# --- Escaped-pipe protection for column parsing ---
# An escaped `\|` inside a table cell shifts awk -F'|' columns and false-FAILs
# C3/C4/C5. Replace each `\|` with a sentinel before any column split; extracted
# cells restore the sentinel to a literal `|`. The sentinel is an improbable
# token carrying no regex metacharacters. Line-based checks keep reading $FILE.
PIPE_SENTINEL='@@ESCPIPE@@'
FILE_COLS=$(sed 's/\\|/'"$PIPE_SENTINEL"'/g' "$FILE")

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

report_malformed "US" '^### US-' '^[0-9]+:### US-[0-9]+([[:space:]]*\(retired\))?:'
report_malformed "AC" '^[[:space:]]*- AC-' '^[0-9]+:[[:space:]]*- AC-[0-9]+\.[0-9]+([[:space:]]*\(retired\))?:'
report_malformed "FR" '^\|[[:space:]]*FR-' '^[0-9]+:\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|'
report_malformed "NFR" '^\|[[:space:]]*NFR-' '^[0-9]+:\|[[:space:]]*NFR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|'

# Collect defined IDs; a `(retired)` mark still counts as defined (US/AC/FR/NFR).
US_IDS=$(grep -E '^### US-[0-9]+([[:space:]]*\(retired\))?:' "$FILE" | sed -E 's/^### (US-[0-9]+).*/\1/')
AC_IDS=$(grep -E '^[[:space:]]*- AC-[0-9]+\.[0-9]+([[:space:]]*\(retired\))?:' "$FILE" | sed -E 's/^[[:space:]]*- (AC-[0-9]+\.[0-9]+).*/\1/')
AC_RETIRED_IDS=$(grep -E '^[[:space:]]*- AC-[0-9]+\.[0-9]+[[:space:]]*\(retired\):' "$FILE" | sed -E 's/^[[:space:]]*- (AC-[0-9]+\.[0-9]+).*/\1/')
FR_IDS=$(grep -E '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE" | sed -E 's/^\|[[:space:]]*(FR-[0-9]+).*/\1/')
NFR_IDS=$(grep -E '^\|[[:space:]]*NFR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE" | sed -E 's/^\|[[:space:]]*(NFR-[0-9]+).*/\1/')

# Minimum-content gate: an artifact with no active (non-retired) user stories or
# no active functional requirements is not reviewable content, even if every
# heading is present. Retired-only entries do not count as active content.
US_ACTIVE_IDS=$(grep -E '^### US-[0-9]+:' "$FILE" | sed -E 's/^### (US-[0-9]+).*/\1/')
FR_ACTIVE_IDS=$(grep -E '^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|' "$FILE" | sed -E 's/^\|[[:space:]]*(FR-[0-9]+).*/\1/')
if [ -z "$US_ACTIVE_IDS" ]; then
    fail_finding "C1" "no user stories found"
fi
if [ -z "$FR_ACTIVE_IDS" ]; then
    fail_finding "C1" "no functional requirements found"
fi

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
# (retired rows exempt from the zero-ref rule). AC refs are read from the
# Acceptance Criteria cell only (awk -F'|' field $5, escaped-pipe sentinel
# applied via FILE_COLS), never the whole row, so a prose AC mention can neither
# satisfy the zero-ref rule nor false-FAIL a row whose AC column is valid.
# Active FR rows must resolve against active (non-retired) AC IDs; a retired FR
# row may reference a retired AC.
FR_ROWS=$(grep -E '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' <<<"$FILE_COLS")
REFERENCED_ACS=""
while IFS= read -r row; do
    [ -z "$row" ] && continue
    frid=$(echo "$row" | sed -E 's/^\|[[:space:]]*(FR-[0-9]+).*/\1/')
    row_retired=0
    echo "$row" | grep -qE '^\|[[:space:]]*FR-[0-9]+[[:space:]]*\(retired\)' && row_retired=1
    accell=$(echo "$row" | awk -F'|' '{ print $5 }')
    refs=$(echo "$accell" | grep -oE 'AC-[0-9]+\.[0-9]+' | sort -u)
    if [ -z "$refs" ]; then
        if [ "$row_retired" -eq 0 ]; then
            fail_finding "C1" "$frid references no AC-N.N IDs in Acceptance Criteria column"
        fi
        continue
    fi
    for r in $refs; do
        REFERENCED_ACS="$REFERENCED_ACS
$r"
        if ! echo "$AC_IDS" | grep -qx "$r"; then
            fail_finding "C1" "$frid references undefined $r"
        elif [ "$row_retired" -eq 0 ] && echo "$AC_RETIRED_IDS" | grep -qx "$r"; then
            fail_finding "C1" "$frid references retired $r"
        fi
    done
done <<EOF
$FR_ROWS
EOF

# Defined AC referenced by no FR row = WARN (retired ACs exempt)
for ac in $AC_IDS; do
    if echo "$AC_RETIRED_IDS" | grep -qx "$ac"; then continue; fi
    if ! echo "$REFERENCED_ACS" | grep -qx "$ac"; then
        warn_finding "C1" "$ac defined but referenced by no FR row"
    fi
done

# Active US story with zero AC-N.N bullets before the next heading = FAIL.
# (retired US headings are exempt; a retired AC bullet still satisfies presence)
C1_ZERO_AC=$(awk '
    function flush() { if (usid != "" && !hasac) print usid }
    /^### US-[0-9]+:/ {
        flush()
        usid = $0; sub(/^### /, "", usid); sub(/:.*/, "", usid)
        hasac = 0
        next
    }
    /^### US-[0-9]+[[:space:]]*\(retired\)/ { flush(); usid = ""; next }
    /^###/ { flush(); usid = ""; next }
    /^##/  { flush(); usid = ""; next }
    usid != "" && /^[[:space:]]*- AC-[0-9]+\.[0-9]+([[:space:]]*\(retired\))?:/ { hasac = 1 }
    END { flush() }
' "$FILE")
for usid in $C1_ZERO_AC; do
    fail_finding "C1" "$usid has no AC-N.N acceptance criteria"
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
C3_HITS=$(awk -F'|' -v S="$PIPE_SENTINEL" '
    /^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|/ {
        id = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); gsub(S, "|", id)
        prio = $4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", prio); gsub(S, "|", prio)
        if (prio != "Must" && prio != "Should" && prio != "Could")
            print id "\t" prio
    }
' <<<"$FILE_COLS")

while IFS="$(printf '\t')" read -r frid prio; do
    [ -z "$frid" ] && continue
    fail_finding "C3" "$frid: Priority \"$prio\" is not a MoSCoW value (Must/Should/Could)"
done <<EOF
$C3_HITS
EOF

# --- C4: Requirement-language lint ---

# Modal presence (FAIL): each active FR row's Requirement cell (2nd table
# column) must contain an uppercase modal MUST, SHOULD, or MAY (covers the
# MoSCoW Could tier phrased as "System MAY ..."; MUST NOT / SHOULD NOT match
# via their MUST / SHOULD stems). Retired rows exempt.
C4_MODAL_HITS=$(awk -F'|' -v S="$PIPE_SENTINEL" '
    /^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|/ {
        id = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); gsub(S, "|", id)
        if ($3 !~ /MUST/ && $3 !~ /SHOULD/ && $3 !~ /MAY/) print id
    }
' <<<"$FILE_COLS")
for frid in $C4_MODAL_HITS; do
    fail_finding "C4" "$frid: Requirement text lacks MUST/SHOULD/MAY modal"
done

# Banned vague terms (WARN, heuristic -- never FAIL): scoped to FR-table rows
# and AC bullets; case-insensitive whole-word match. AC bullets are joined with
# their continuation lines (mirrors the C2 AC_BLOCKS join) so a banned term on a
# wrapped AC line is scanned as part of its logical AC unit. Each record is
# "<lineno>:<text>" (AC blocks report the bullet's starting line).
C4_FR_LINES=$(grep -nE '^\|[[:space:]]*FR-[0-9]+([[:space:]]*\(retired\))?[[:space:]]*\|' "$FILE")
C4_AC_BLOCKS=$(awk '
    function flush() { if (inac) print startnr ":" text }
    /^[[:space:]]*- AC-[0-9]+\.[0-9]+:/ {
        flush()
        inac = 1; startnr = NR; text = $0
        next
    }
    /^[[:space:]]*$/ { flush(); inac = 0; next }
    /^[[:space:]]*- / { flush(); inac = 0; next }
    { if (inac) text = text " " $0 }
    END { flush() }
' "$FILE")
C4_SCOPED=$(printf '%s\n%s\n' "$C4_FR_LINES" "$C4_AC_BLOCKS")
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

# --- C5: NFR fill-or-N/A ---

# Each active NFR row's Metric ($4) and Target ($5) cells must be non-empty and
# free of {{...}} placeholders. Rows whose Target is "N/A: <reason>" are exempt,
# but a placeholder reason ("N/A: {{reason}}") does NOT earn the exemption and
# falls through to the unfilled-placeholder FAIL. Bare "N/A" (no ": reason") in
# either cell = FAIL. Retired rows not matched.
C5_HITS=$(awk -F'|' -v S="$PIPE_SENTINEL" '
    /^\|[[:space:]]*NFR-[0-9]+[[:space:]]*\|/ {
        id = $2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); gsub(S, "|", id)
        metric = $4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", metric); gsub(S, "|", metric)
        target = $5; gsub(/^[[:space:]]+|[[:space:]]+$/, "", target); gsub(S, "|", target)
        if (target ~ /^N\/A:[[:space:]]*[^[:space:]]/ && target !~ /\{\{/) next
        msg = ""
        if (metric == "") msg = "Metric cell is empty"
        else if (metric ~ /\{\{/) msg = "Metric contains unfilled placeholder"
        else if (metric == "N/A") msg = "Metric is bare N/A without \": reason\""
        else if (target == "") msg = "Target cell is empty"
        else if (target ~ /\{\{/) msg = "Target contains unfilled placeholder"
        else if (target == "N/A") msg = "Target is bare N/A without \": reason\""
        if (msg != "") print id "\t" msg
    }
' <<<"$FILE_COLS")

while IFS="$(printf '\t')" read -r nfrid msg; do
    [ -z "$nfrid" ] && continue
    fail_finding "C5" "$nfrid: $msg"
done <<EOF
$C5_HITS
EOF

# --- C6: Six-scenario coverage proxy (WARN-class, heuristic -- never FAIL) ---

# Split doc into story blocks (`### US-N:` to next heading). A story passes if
# any AC line (bullet or continuation) matches a non-happy-path keyword
# (case-insensitive) OR the block contains an `N/A:` scenario line.
C6_HITS=$(awk '
    function flush() { if (usid != "" && !ok) print usid }
    /^### US-[0-9]+:/ {
        flush()
        usid = $0; sub(/^### /, "", usid); sub(/:.*/, "", usid)
        ok = 0; inac = 0
        next
    }
    /^##/ { flush(); usid = ""; next }
    usid != "" {
        if ($0 ~ /N\/A:/) { ok = 1; next }
        if ($0 ~ /^[[:space:]]*- AC-[0-9]+\.[0-9]+:/) inac = 1
        else if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*- /) inac = 0
        if (inac && tolower($0) ~ /error|invalid|missing|empty|cancel|denied|unauthorized|limit|boundary/) ok = 1
    }
    END { flush() }
' "$FILE")

for usid in $C6_HITS; do
    warn_finding "C6" "$usid: happy-path-only ACs, no N/A markings"
done

# --- C7: unowned TBD / open questions (WARN-class, never FAIL) ---

# Every TBD must carry an (owner, date)-style parenthetical: `TBD (` followed
# by comma-separated content. Strip well-formed occurrences; any TBD left on
# the line is bare.
C7_TBD_LINES=$(grep -nw 'TBD' "$FILE")
if [ -n "$C7_TBD_LINES" ]; then
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        stripped=$(echo "${line#*:}" | sed -E 's/TBD[[:space:]]*\([^)]*,[^)]*\)//g')
        if echo "$stripped" | grep -qw 'TBD'; then
            warn_finding "C7" "bare TBD without (owner, date) at line ${line%%:*}"
        fi
    done <<EOF
$C7_TBD_LINES
EOF
fi

# Every bullet under `## Unresolved Questions` (until next heading) must
# contain `Owner:`.
C7_UQ_HITS=$(awk '
    /^## Unresolved Questions/ { insec = 1; next }
    /^##/ { insec = 0 }
    insec && /^[[:space:]]*- / && $0 !~ /Owner:/ {
        item = $0; sub(/^[[:space:]]*- /, "", item)
        print NR "\t" item
    }
' "$FILE")

while IFS="$(printf '\t')" read -r lineno item; do
    [ -z "$lineno" ] && continue
    warn_finding "C7" "unowned question at line $lineno: $item"
done <<EOF
$C7_UQ_HITS
EOF

# --- C8: MUST:SHOULD ratio advisory (WARN-class, never FAIL) ---

# Count active FR rows and Must-priority rows (retired rows not matched).
# Suppressed entirely when total FRs < 8 (advisory meaningless at small N).
C8_COUNTS=$(awk -F'|' -v S="$PIPE_SENTINEL" '
    /^\|[[:space:]]*FR-[0-9]+[[:space:]]*\|/ {
        total++
        prio = $4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", prio); gsub(S, "|", prio)
        if (prio == "Must") must++
    }
    END { print total+0 "\t" must+0 }
' <<<"$FILE_COLS")
C8_TOTAL=${C8_COUNTS%%$(printf '\t')*}
C8_MUST=${C8_COUNTS##*$(printf '\t')}

if [ "$C8_TOTAL" -ge 8 ] && [ $((C8_MUST * 100)) -gt $((C8_TOTAL * 85)) ]; then
    warn_finding "C8" "no cut-line signal: $C8_MUST of $C8_TOTAL FRs are Must"
fi

# --- Summary ---
# Counts are checks by worst status (FAIL > WARN > PASS), always summing to 8.
CHECK_FAIL=0
CHECK_WARN=0
CHECK_PASS=0
for n in 1 2 3 4 5 6 7 8; do
    eval "status=\$C${n}_STATUS"
    # Emit exactly one canonical status line per check (all 8 always present).
    echo "CHECK|C${n}|${status}"
    case "$status" in
        FAIL) CHECK_FAIL=$((CHECK_FAIL + 1)) ;;
        WARN) CHECK_WARN=$((CHECK_WARN + 1)) ;;
        *) CHECK_PASS=$((CHECK_PASS + 1)) ;;
    esac
done

if [ "$CHECK_FAIL" -gt 0 ]; then
    echo "RESULT: FAIL ($CHECK_FAIL FAIL, $CHECK_WARN WARN, $CHECK_PASS PASS)"
    exit 1
else
    echo "RESULT: PASS ($CHECK_FAIL FAIL, $CHECK_WARN WARN, $CHECK_PASS PASS)"
    exit 0
fi
