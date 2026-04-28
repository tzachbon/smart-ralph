#!/usr/bin/env bash
set -euo pipefail

# BMAD Bridge — import.sh
# Structural mapper: BMAD → smart-ralph spec files

# Error handling helper
function error_exit() {
    local msg="$1"
    echo "Error: $msg" >&2
    # Log to temp warning file if defined
    if [[ -n "${WARNING_FILE:-}" ]]; then
        echo "[$(date -Iseconds)] $msg" >> "$WARNING_FILE" 2>/dev/null || true
    fi
    exit 1
}

# Dependency check
command -v jq >/dev/null 2>&1 || error_exit "jq is required"

# --- Placeholder Functions ---

function validate_inputs() {
    local bmad_root="$1"
    local spec_name="$2"

    # Reject paths containing literal '..' components
    if [[ "$bmad_root" == *".."* ]]; then
        error_exit "BMAD root '$bmad_root' contains path traversal ('..')"
    fi

    if [[ "$spec_name" == *".."* ]]; then
        error_exit "spec name '$spec_name' contains path traversal ('..')"
    fi

    # Resolve BMAD root to absolute path
    local abs_bmad_root
    abs_bmad_root="$(cd "$bmad_root" && pwd)" || error_exit "Cannot resolve BMAD root '$bmad_root'"

    if [[ ! -d "$abs_bmad_root" ]]; then
        error_exit "BMAD root resolved to non-existent path '$abs_bmad_root'"
    fi

    local project_root
    project_root="$(cd . && pwd)"
    if [[ "$abs_bmad_root" != "$project_root"* && "$abs_bmad_root" != "$project_root" ]]; then
        error_exit "BMAD root must be within project root (resolved to '$abs_bmad_root')"
    fi

    local spec_dir_full="${project_root}/specs/${spec_name}"
    if [[ -d "$spec_dir_full" ]]; then
        error_exit "spec directory '${spec_dir_full}' already exists"
    fi

    # Minimum 2 characters
    if [[ ${#spec_name} -lt 2 ]]; then
        error_exit "spec name '$spec_name' must be at least 2 characters"
    fi

    # Stricter format: starts with lowercase letter, each subsequent group is optionally hyphen + one or more alphanumerics
    # This rejects: leading hyphens, trailing hyphens, consecutive hyphens, uppercase, special chars, single chars
    if ! [[ "$spec_name" =~ ^[a-z](-?[a-z0-9]+)*$ ]]; then
        error_exit "spec name '$spec_name' is invalid (must match ^[a-z](-?[a-z0-9]+)*$, at least 2 chars, no leading/trailing/consecutive hyphens)"
    fi
}

function resolve_bmad_paths() {
    local project_root="$1"
    local config_file="${project_root}/_bmad/config.toml"

    # Check for BMAD config file first
    if [[ -f "$config_file" ]]; then
        local configured_path
        configured_path=$(grep -E '^\s*planning_artifacts\s*=' "$config_file" 2>/dev/null | head -1 | sed 's/.*=\s*//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//') || true
        if [[ -n "$configured_path" ]]; then
            # Resolve configured path relative to project root
            if [[ "$configured_path" != /* ]]; then
                configured_path="${project_root}/${configured_path}"
            fi
            if [[ -d "$configured_path" ]]; then
                BMAD_PLANNING="$configured_path"
            fi
        fi
    fi

    # Fall back to default hyphen variant
    if [[ -z "${BMAD_PLANNING:-}" ]] || [[ ! -d "$BMAD_PLANNING" ]]; then
        BMAD_PLANNING="${project_root}/_bmad-output/planning-artifacts"
    fi
    if [[ ! -d "$BMAD_PLANNING" ]]; then
        BMAD_PLANNING="${project_root}/_bmad-output/planning_artifacts"
    fi

    BMAD_PRD="$(cd "$BMAD_PLANNING" && realpath "prd.md")"
    BMAD_EPICS="$(cd "$BMAD_PLANNING" && realpath "epics.md")"
    BMAD_ARCH="$(cd "$BMAD_PLANNING" && realpath "architecture.md")"
}

function parse_prd_frs() {
    local prd_path="$1"
    local output_path="$2"

    # Extract FR lines from Functional Requirements section, then parse
    {
        awk '
        /## Functional Requirements/ { in_section=1; next }
        in_section && /^## / { exit }
        in_section && /^- FR[0-9]+:.*\[.*\] can / { print }
        ' "$prd_path"
    } | extract_fr_lines > "$output_path"

    local count
    count=$(tail -1 "$output_path")
    echo "$count" | grep -o '^[0-9]*'

    return 0
}

function extract_fr_lines() {
    local id actor cap metric target item_count=0
    local -a ids actors caps stories nfr_metrics nfr_targets

    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        if [[ "$line" == *FR* && "$line" == *"["* ]]; then
            # FR-format: - FR123: [Actor] capability text
            id="${line#- FR}"
            id="${id%%:*}"
            actor="${line#*\[}"
            actor="${actor%%\]*}"
            cap="${line#*] can }"
            item_count=$((item_count + 1))
            ids[$item_count]="$id"
            actors[$item_count]="$actor"
            caps[$item_count]="$cap"
            stories[$item_count]="As a $actor, I want to $cap."
        else
            # NFR-format: - Metric: Target description
            metric="${line#- }"
            metric="${metric%%:*}"
            target="${line#*: }"
            target="${target#- }"
            item_count=$((item_count + 1))
            nfr_metrics[$item_count]="$metric"
            nfr_targets[$item_count]="$target"
            stories[$item_count]="NFR ${metric}: ${target}."
        fi
    done

    # Output appropriate section header based on detected format
    if [[ $item_count -gt 0 && "${stories[1]}" == NFR* ]]; then
        echo "## Non-Functional Requirements"
        echo ""
        echo "| NFR | Metric | Target |"
        echo "|-----|--------|--------|"
        local i
        for ((i = 1; i <= item_count; i++)); do
            echo "| NFR-${i} | ${nfr_metrics[$i]} | ${nfr_targets[$i]} |"
        done
    else
        echo "## User Stories"
        echo ""
        local i
        for ((i = 1; i <= item_count; i++)); do
            echo "$i. ${stories[$i]}"
        done
        echo ""
        echo "## Functional Requirements"
        echo ""
        echo "| FR ID | Actor | Capability |"
        echo "|-------|-------|------------|"
        for ((i = 1; i <= item_count; i++)); do
            echo "| FR-${ids[$i]} | ${actors[$i]} | ${caps[$i]} |"
        done
    fi
    echo ""
    echo "$item_count items extracted."

    return 0
}

function parse_prd_nfrs() {
    local prd_path="$1"
    local output_path="$2"

    # Check if NFR section exists
    if ! grep -q '## Non-Functional Requirements' "$prd_path" 2>/dev/null; then
        return 0
    fi

    printf "## Non-Functional Requirements\n\n" >> "$output_path"

    # Extract NFR subsections and bullets, preserving ### headings and NFR numbering
    awk '
    /## Non-Functional Requirements/ { in_section=1; next }
    !in_section { next }
    /^## / { exit }
    /^### / {
        subsection=$0
        sub(/^### */, "", subsection)
        printf "\n### %s\n\n", subsection
        printf "| NFR | Metric | Target |\n"
        printf "|-----|--------|--------|\n"
        next
    }
    /^- / {
        nfr_num++
        line = $0
        sub(/^- /, "", line)
        sub(/[[:space:]]*$/, "", line)
        if (line ~ /:/) {
            idx = index(line, ":")
            metric = substr(line, 1, idx-1)
            target = substr(line, idx+1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", metric)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", target)
        } else {
            metric = line
            target = "—"
        }
        printf "| NFR-%d | %s | %s |\n", nfr_num, metric, (target == "" ? "—" : target)
    }
    ' "$prd_path" >> "$output_path"

    return 0
}

# Extract story title from a raw "### Story N.M: Title" heading line.
# Usage: extract_story_title "### Story 1.2: User Authentication"
# Output: "User Authentication"
function extract_story_title() {
    local raw="$1"
    local title
    title="$(echo "$raw" | sed -E 's/^### Story [0-9]+\.[0-9]+:[[:space:]]*//' | sed -E 's/[[:space:]]+$//')"
    echo "$title"
}

# Build FR coverage map from epics file.
# Parses the "### FR Coverage Map" section and outputs lines in format:
# STORY_NUM<TAB>FR-REFS (e.g., "1.1\tFR-1, FR-2")
# Usage: build_coverage_map "$epics_path"
function build_coverage_map() {
    local epics_path="$1"

    # Extract the FR Coverage Map section
    local coverage_map
    coverage_map=$(awk '
        /### FR Coverage Map/ { in_map=1; next }
        in_map && /^### / { exit }
        in_map { print }
    ' "$epics_path" 2>/dev/null) || return 0

    # Parse each line into STORY_NUM<TAB>FR-REFS format
    if [[ -z "$coverage_map" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        # Match lines like "Story 1.1 - FR-1, FR-2" or "1.1 -> FR-1, FR-3"
        if [[ "$line" =~ Story[[:space:]]+([0-9]+\.[0-9]+) ]] || [[ "$line" =~ ^([0-9]+\.[0-9]+)[[:space:]]*[=\>][[:space:]]* ]]; then
            local snum="${BASH_REMATCH[1]}"
            # Extract FR refs
            local frs=""
            local tmp="$line"
            while [[ "$tmp" =~ (FR[-]?[0-9]+) ]]; do
                if [[ -n "$frs" ]]; then
                    frs="$frs, ${BASH_REMATCH[1]}"
                else
                    frs="${BASH_REMATCH[1]}"
                fi
                tmp="${tmp#*"${BASH_REMATCH[0]}"}"
            done
            printf '%s\t%s\n' "$snum" "$frs"
        fi
    done <<< "$coverage_map"
}

function parse_epics() {
    local epics_path="$1"
    local output_path="$2"
    local spec_name="${3:-bmad-import}"

    if [[ ! -f "$epics_path" ]]; then
        echo "Warning: epics file '$epics_path' not found" >&2
        # Write minimal tasks.md with Phase 1 placeholder
        cat > "$output_path" << ENDTPL
---
spec: ${spec_name}
phase: tasks
created: PLACEHOLDER_CREATED
total_tasks: 0
---

# Tasks: BMAD Import

## Phase 1: Make It Work (POC)

No epics file found. Manual task creation required.
ENDTPL
        return 0
    fi

    # Build coverage map: story_num -> fr_refs
    local coverage_tmp
    coverage_tmp=$(mktemp)
    build_coverage_map "$epics_path" > "$coverage_tmp" 2>/dev/null || true

    # Read coverage map into arrays
    local -a cov_story_nums=()
    local -a cov_fr_refs=()
    if [[ -s "$coverage_tmp" ]]; then
        while IFS=$'\t' read -r snum frs; do
            cov_story_nums+=("$snum")
            cov_fr_refs+=("$frs")
        done < "$coverage_tmp"
    fi
    rm -f "$coverage_tmp"

    # Pre-process: extract story titles using extract_story_title()
    local story_titles_tmp
    story_titles_tmp=$(mktemp)
    while IFS= read -r line; do
        story_num="${line#*Story }"
        story_num="${story_num%%:*}"
        story_title="$(extract_story_title "$line")"
        echo "${story_num}|${story_title}"
    done < <(grep -E '^### Story [0-9]+\.[0-9]+:' "$epics_path") > "$story_titles_tmp"

    # awk state-machine: extract story blocks with title + ACs
    local story_count
    story_count=$(awk '
        /### Story [0-9]+\.[0-9]+/ { count++ }
        END { print count+0 }
    ' "$epics_path")

    # Generate tasks.md using awk state-machine
    awk -v story_count="$story_count" -v story_titles_file="$story_titles_tmp" '
    BEGIN {
        in_story = 0
        story_idx = 0
        story_num = ""
        story_title = ""
        in_ac = 0
        given = ""
        when_ac = ""
        then_ac = ""
        total = 0

        # Load story title mapping from pre-processed file
        while ((getline mline < story_titles_file) > 0) {
            split(mline, mparts, "|")
            story_titles[mparts[1]] = mparts[2]
        }
        close(story_titles_file)
    }

    function extract_bdd_criteria(line,    type, text) {
        if (match(line, /\*\*Given\*\*/)) {
            text = line; sub(/.*\*\*Given\*\*/, "", text)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
            return "GIVEN:" text
        }
        if (match(line, /\*\*When\*\*/)) {
            text = line; sub(/.*\*\*When\*\*/, "", text)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
            return "WHEN:" text
        }
        if (match(line, /\*\*Then\*\*/)) {
            text = line; sub(/.*\*\*Then\*\*/, "", text)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", text)
            return "THEN:" text
        }
        return ""
    }

    # Detect story heading ### Story N.M: Title
    /### Story [0-9]+\.[0-9]+:/ {
        if (in_story && story_idx > 0) {
            # End of previous story before starting new one
            total++
            _print_task()
        }
        in_story = 1
        in_ac = 0
        story_idx++
        given = ""
        when_ac = ""
        then_ac = ""

        line = $0
        sub(/^### Story */, "", line)
        story_num = line
        sub(/:.*/, "", story_num)

        # Title from pre-processed mapping via extract_story_title()
        story_title = story_titles[story_num]
        next
    }

    # Skip FR Coverage Map section (already parsed above)
    in_story && /### FR Coverage Map/ {
        in_story = 0
        next
    }

    # Story boundary: new heading at ### level or higher means new story
    in_story && /^### / && !/### Story / {
        # End of current story block - print the task
        total++
        _print_task()
        next
    }

    # Acceptance Criteria header
    in_story && /\*\*Acceptance Criteria:\*\*/ {
        in_ac = 1
        next
    }

    # Extract Given/When/Then via extract_bdd_criteria()
    in_story && in_ac && /(\*\*Given\*\*|\*\*When\*\*|\*\*Then\*\*)/ {
        result = extract_bdd_criteria($0)
        if (result ~ /^GIVEN:/) given = substr(result, 7)
        else if (result ~ /^WHEN:/) when_ac = substr(result, 7)
        else if (result ~ /^THEN:/) then_ac = substr(result, 7)
        next
    }

    function _print_task() {
        printf "\n### Story %s: %s\n", story_num, story_title
        printf "- [ ] %s %s\n", story_num, story_title
        printf "  - **Do**:\n"
        printf "    1. Implement story: %s\n", story_title
        if (given != "" && when_ac != "" && then_ac != "") {
            printf "    2. Verify Given: %s\n", given
            printf "    3. Verify When: %s\n", when_ac
            printf "    4. Verify Then: %s\n", then_ac
        } else {
            printf "    2. Verify feature \"%s\" works as expected\n", story_title
        }
        printf "  - **Files**:\n"
        printf "    TODO: determine files from story context\n"
        printf "  - **Done when**:\n"
        if (given != "" && when_ac != "" && then_ac != "") {
            printf "    Acceptance criteria met: Given \"%s\", When \"%s\", Then \"%s\"\n", given, when_ac, then_ac
        } else {
            printf "    Feature \"%s\" is implemented and passing tests\n", story_title
        }
        printf "  - **Verify**:\n"
        if (given != "" && when_ac != "" && then_ac != "") {
            printf "    grep -q \"%s\" <output> && echo \"PASS\"\n", then_ac
        } else {
            printf "    grep -q \"%s\" <output> && echo \"PASS\"\n", story_title
        }
        printf "  - **Commit**:\n"
        printf "    feat: implement story %s - %s\n", story_num, story_title
    }

    END {
        # If last story was not terminated by another heading, print it
        if (in_story && story_idx > 0) {
            total++
            _print_task()
        }
    }
    ' "$epics_path" > /tmp/_epics_tasks_tmp_$$

    # Build output file
    {
        echo "---"
        echo "spec: bmad-import"
        echo "phase: tasks"
        echo "created: $(date -Iseconds)"
        echo "total_tasks: $story_count"
        echo "---"
        echo ""
        echo "# Tasks: BMAD Import"
        echo ""
        echo "## Phase 1: Make It Work (POC)"
        echo ""
        cat /tmp/_epics_tasks_tmp_$$
        echo ""
        echo "## Phase 2: Refactoring"
        echo ""
        echo "TODO: Refactor imported code"
        echo ""
        echo "## Phase 3: Testing"
        echo ""
        echo "TODO: Add tests"
        echo ""
        echo "## Phase 4: Quality Gates"
        echo ""
        echo "TODO: Final validation"
        echo ""
        echo "## Phase 5: PR Lifecycle"
        echo ""
        echo "TODO: CI and review"
    } > "$output_path"

    rm -f "$story_titles_tmp"

    echo "$story_count" "stories extracted."
    return 0
}

# Write a table section from architecture.md: finds matching ## headings and outputs rows.
# For decisions: first column = section heading, second = content
# For structure: first and second columns = content line
# Usage: write_arch_table "$arch_path" "$heading_pattern" "$mode"  (mode: "decisions" or "structure")
write_arch_table() {
    local arch_path="$1" heading_pat="$2" mode="$3"
    if [[ "$mode" == "decisions" ]]; then
        awk -v hp="$heading_pat" '
        /^## / {
            h = $0; sub(/^## */, "", h); sub(/ *$/, "", h); lower = tolower(h)
            if (lower ~ hp) { in_block = 1; label = h; next }
            else { in_block = 0 }
        }
        in_block && /^- / { line = $0; sub(/^- /, "", line); sub(/\n$/, "", line); printf "| %s | %s |\n", label, line }
        in_block && /^[^#]/ && !/^$/ { printf "| %s | %s |\n", label, $0 }
        ' "$arch_path"
    else
        awk -v hp="$heading_pat" '
        /^## / {
            h = $0; sub(/^## */, "", h); sub(/ *$/, "", h); lower = tolower(h)
            if (lower ~ hp) { in_block = 1; next }
            else { in_block = 0 }
        }
        in_block && /^- / { line = $0; sub(/^- /, "", line); sub(/\n$/, "", line); printf "| %s | %s |\n", line, line }
        in_block && /^[^#]/ && !/^$/ { printf "| %s | %s |\n", $0, $0 }
        ' "$arch_path"
    fi
}

function parse_architecture() {
    local arch_path="$1" output_path="$2" append_mode="${3:-}" spec_name="${4:-bmad-import}"

    if [[ ! -f "$arch_path" ]]; then
        if [[ -n "$append_mode" ]]; then
            printf "\n## Architecture\n\nArchitecture input not provided\n" >> "$output_path"
        else
            {
                echo "---"; echo "spec: ${spec_name}"; echo "phase: design"
                echo "created: $(date -Iseconds)"; echo '---'
                echo ""; echo "# Design: Architecture"; echo ""
                echo "## Overview"; echo ""; echo "Architecture input not provided"
            } > "$output_path"
        fi
        return 0
    fi

    # Detect section keywords
    local has_decisions=0 has_structure=0
    while IFS= read -r line; do
        local lower; lower="$(echo "$line" | tr '[:upper:]' '[:lower:]')"
        echo "$lower" | grep -qiE 'decision|technology|stack' && has_decisions=1
        echo "$lower" | grep -qiE 'structure' && has_structure=1
    done < <(grep -E '^#{2,} ' "$arch_path")

    local start_block
    if [[ -z "$append_mode" ]]; then
        start_block='---
spec: '"${spec_name}"'
phase: design
created: '"$(date -Iseconds)"'
---

# Design: Architecture

## Overview

Architecture mapped from BMAD architecture.md
'
    fi

    # Write tables and remaining headings to a temp file, then write/appending to output
    local arch_tmp
    arch_tmp=$(mktemp)

    {
        # Technical Decisions table
        if [[ $has_decisions -eq 1 ]]; then
            echo "## Technical Decisions"
            echo ""
            echo "| Decision | Details |"
            echo "|----------|---------|"
            write_arch_table "$arch_path" 'decisions|technology|stack' 'decisions'
            echo ""
        fi

        # File Structure table
        if [[ $has_structure -eq 1 ]]; then
            echo "## File Structure"
            echo ""
            echo "| Path | Description |"
            echo "|------|-------------|"
            write_arch_table "$arch_path" 'project structure|file structure' 'structure'
            echo ""
        fi

        # Remaining ## headings as Architecture subsections
        echo "## Architecture"
        echo ""
        awk '
        /^## / {
            h = $0; sub(/^## */, "", h); sub(/ *$/, "", h); lower = tolower(h)
            if (lower ~ /decisions|technology|stack|project structure|file structure/) next
            print "### " h; print ""
        }
        ' "$arch_path"
    } > "$arch_tmp"

    if [[ -z "$append_mode" ]]; then
        echo "$start_block" > "$output_path"
        cat "$arch_tmp" >> "$output_path"
    else
        cat "$arch_tmp" >> "$output_path"
    fi

    rm -f "$arch_tmp"
}

function write_state() {
    local spec_dir="$1"
    local spec_name="$2"
    local total_tasks="$3"

    jq -n \
        --arg name "$spec_name" \
        --arg basePath "$spec_dir" \
        --argjson totalTasks "$total_tasks" \
        '{
            source: "spec",
            name: $name,
            basePath: $basePath,
            phase: "tasks",
            taskIndex: 0,
            totalTasks: $totalTasks,
            granularity: "fine",
            epicName: null
        }' > "${spec_dir}/.ralph-state.json"
}

function validate_output() {
    local spec_dir="${1:-.}"

    for file in requirements.md design.md tasks.md; do
        local filepath="${spec_dir}/${file}"
        if [[ ! -f "$filepath" ]]; then
            echo "Warning: ${filepath} does not exist, skipping" >&2
            continue
        fi

        # Check frontmatter fields
        for field in spec phase created; do
            if ! grep -q "^${field}:" "$filepath"; then
                error_exit "${filepath} missing required frontmatter field: ${field}"
            fi
        done
    done

    # Check tasks.md has total_tasks
    local tasks_file="${spec_dir}/tasks.md"
    if [[ -f "$tasks_file" ]]; then
        if ! grep -q "^total_tasks:" "$tasks_file"; then
            error_exit "${tasks_file} missing required frontmatter field: total_tasks"
        fi
    fi

    return 0
}

function write_frontmatter() {
    local file="$1"
    local phase="$2"
    local spec_name="$3"
    local total_tasks="${4:-}"
    local created
    created="$(date -Iseconds)"

    {
        echo '---'
        echo "spec: ${spec_name}"
        echo "phase: ${phase}"
        echo "created: ${created}"
        if [[ -n "$total_tasks" ]]; then
            echo "total_tasks: ${total_tasks}"
        fi
        echo '---'
    } > "$file"
}

function generate_requirements() {
    local spec_dir="${SPEC_DIR:-specs/${MAIN_SPEC_NAME:-bmad-import}}"
    local prd_path="${1:-$BMAD_PRD}"
    local req_file="${2:-${spec_dir}/requirements.md}"
    local spec_name="${3:-$MAIN_SPEC_NAME}"
    local FR_TMP=""
    local NFR_TMP=""

    write_frontmatter "$req_file" "requirements" "$spec_name"

    if [[ -f "$prd_path" ]]; then
        # Extract PRD title for Goal section
        local prd_title
        prd_title=$(grep -m1 '^# ' "$prd_path" | sed 's/^# *//')
        if [[ -z "$prd_title" ]]; then
            prd_title="BMAD Requirements"
        fi

        # Add Goal section
        {
            echo ""
            echo "## Goal"
            echo ""
            echo "$prd_title"
        } >> "$req_file"

        # Extract FRs (User Stories + FR table)
        FR_TMP=$(mktemp)
        FR_COUNT=$(parse_prd_frs "$prd_path" "$FR_TMP" 2>/dev/null)

        # Extract NFRs
        NFR_TMP="${FR_TMP}.nfr"
        parse_prd_nfrs "$prd_path" "$NFR_TMP" 2>/dev/null

        # Append FR + NFR content
        {
            cat "$FR_TMP"
            echo ""
            if [[ -f "$NFR_TMP" ]]; then
                cat "$NFR_TMP"
                local nfr_lines
                nfr_lines=$(grep -c '| ' "$NFR_TMP" 2>/dev/null || true)
                NFR_COUNT="${nfr_lines:-0}"
                rm -f "$NFR_TMP"
            else
                NFR_COUNT=0
            fi
        } >> "$req_file"

        # Add Glossary
        {
            echo ""
            echo "## Glossary"
            echo ""
            echo "| Term | Definition |"
            echo "|------|------------|"
            echo ""
        } >> "$req_file"

        # Add Out of Scope
        {
            echo "## Out of Scope"
            echo ""
            echo "Content to be determined from BMAD artifacts"
            echo ""
        } >> "$req_file"

        # Add Dependencies
        {
            echo "## Dependencies"
            echo ""
            echo "- BMAD v2.11.0+ output artifact format"
            echo "- jq must be available on the host system"
            echo "- bash 4.0+ or POSIX-compatible shell"
            echo ""
        } >> "$req_file"

        rm -f "$FR_TMP"
    else
        echo "Warning: No PRD found, requirements will be empty" >&2
        FR_COUNT=0
        NFR_COUNT=0
    fi
}

function generate_tasks() {
    local spec_dir="${SPEC_DIR:-specs/${MAIN_SPEC_NAME:-bmad-import}}"
    local epics_path="${1:-$BMAD_EPICS}"
    local tasks_file="${2:-${spec_dir}/tasks.md}"
    local spec_name="${3:-bmad-import}"
    local warnings=()

    # Strip existing YAML frontmatter from a file (lines between --- markers at start)
    _strip_frontmatter() {
        awk 'NR==1 && /^---$/{skip=1; next} skip && /^---$/{skip=0; next} !skip{print}' "$1"
    }

    if [[ -f "$epics_path" ]]; then
        # Count stories from the epics file for total_tasks in frontmatter
        STORY_COUNT=$(grep -c '### Story' "$epics_path" 2>/dev/null || echo 0)

        # Generate Phase 1 content using parse_epics (writes full tasks.md to temp file)
        local epics_tmp
        epics_tmp=$(mktemp)
        parse_epics "$epics_path" "$epics_tmp" "$spec_name" 2>/dev/null

        # Build output: frontmatter + Phase 1 from parse_epics (stripped of its frontmatter/footer) + Phase 2-5 placeholders
        {
            echo '---'
            echo "spec: ${spec_name}"
            echo "phase: tasks"
            echo "created: $(date -Iseconds)"
            echo "total_tasks: ${STORY_COUNT}"
            echo '---'
            echo ""
            echo "# Tasks: ${spec_name}"
            echo ""
            # Extract Phase 1 content (between "## Phase 1:" and "## Phase 2:")
            sed -n '/^## Phase 1:/,/^## Phase 2:/{/^## Phase 2:/d;p}' "$epics_tmp"
            echo ""
            # Write Phase 2-5 as template placeholders
            echo "## Phase 2: Refactoring"
            echo ""
            echo "TODO: Refactor imported code"
            echo ""
            echo "## Phase 3: Testing"
            echo ""
            echo "TODO: Add tests"
            echo ""
            echo "## Phase 4: Quality Gates"
            echo ""
            echo "TODO: Final validation"
            echo ""
            echo "## Phase 5: PR Lifecycle"
            echo ""
            echo "TODO: CI and review"
        } > "$tasks_file"

        rm -f "$epics_tmp"
    else
        echo "Warning: No epics file found, minimal tasks.md generated" >&2
        warnings+=("No epics file found")
        cat > "$tasks_file" << ENDTPL
---
spec: ${spec_name}
phase: tasks
created: $(date -Iseconds)
total_tasks: 0
---

# Tasks: ${spec_name}

## Phase 1: Make It Work (POC)

No epics file found. Manual task creation required.

## Phase 2: Refactoring

TODO: Refactor imported code

## Phase 3: Testing

TODO: Add tests

## Phase 4: Quality Gates

TODO: Final validation

## Phase 5: PR Lifecycle

TODO: CI and review
ENDTPL
    fi
}

function generate_design() {
    local spec_dir="${SPEC_DIR:-specs/${MAIN_SPEC_NAME:-bmad-import}}"
    local arch_path="${1:-$BMAD_ARCH}"
    local design_file="${2:-${spec_dir}/design.md}"
    local warnings=()
    local design_title="BMAD Architecture"
    local main_spec="${MAIN_SPEC_NAME:-bmad-import}"
    local created
    created="$(date -Iseconds)"

    # Write frontmatter
    write_frontmatter "$design_file" "design" "$main_spec"

    # Add Overview section
    {
        echo ""
        echo "## Overview"
        echo ""
        echo "$design_title"
        echo ""
    } >> "$design_file"

    # Call parse_architecture to fill Architecture, Technical Decisions, File Structure
    if [[ -f "$arch_path" ]]; then
        parse_architecture "$arch_path" "$design_file" "append" "$main_spec"
        ARCH_COUNT=$(grep -c '^## ' "$design_file" 2>/dev/null || echo 0)
    else
        echo "Warning: No architecture.md found, minimal design.md generated" >&2
        warnings+=("No architecture.md found")
        parse_architecture "$arch_path" "$design_file" "append" "$main_spec"
        ARCH_COUNT=0
    fi

    # Add empty template sections for BMAD-specific details
    {
        echo ""
        echo "## Interfaces"
        echo ""
        echo "TODO: Document external interfaces, APIs, and integrations"
        echo ""
        echo "## Error Handling"
        echo ""
        echo "TODO: Document error handling strategies and recovery procedures"
        echo ""
        echo "## Edge Cases"
        echo ""
        echo "TODO: Document edge cases and boundary conditions"
        echo ""
        echo "## Dependencies"
        echo ""
        echo "- BMAD v2.11.0+ output artifact format"
        echo "- jq must be available on the host system"
        echo "- bash 4.0+ or POSIX-compatible shell"
    } >> "$design_file"
}

function print_summary() {
    local fr_count="$1"
    local nfr_count="$2"
    local story_count="$3"
    local arch_sections="$4"
    shift 4 2>/dev/null || true

    echo "=== BMAD Import Summary ==="
    echo "Mapped ${fr_count} functional requirements, ${nfr_count} non-functional requirements, ${story_count} stories"
    echo "Architecture sections: ${arch_sections}"
    echo ""
    echo "## Warnings"

    local warning
    for warning in "$@"; do
        echo "- ${warning}"
    done

    if [[ $# -eq 0 ]]; then
        echo "- No warnings"
    fi
}

# --- Main Flow ---

# Guard: only run when executed directly, not when sourced (for testing)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] || return 0

MAIN_BMAD_ROOT="${1:?Usage: import.sh <bmad-root> <spec-name>}"
MAIN_SPEC_NAME="${2:?Usage: import.sh <bmad-root> <spec-name>}"

FR_COUNT=0
NFR_COUNT=0
STORY_COUNT=0
ARCH_COUNT=0

validate_inputs "$MAIN_BMAD_ROOT" "$MAIN_SPEC_NAME"
resolve_bmad_paths "$MAIN_BMAD_ROOT"

# Create output directory
SPEC_DIR="specs/${MAIN_SPEC_NAME}"
mkdir -p "$SPEC_DIR"

# Generate requirements
generate_requirements

# Generate tasks
generate_tasks "$BMAD_EPICS" "${SPEC_DIR}/tasks.md" "$MAIN_SPEC_NAME"

# Generate design
generate_design "$BMAD_ARCH" "${SPEC_DIR}/design.md"

# Write state
write_state "$SPEC_DIR" "$MAIN_SPEC_NAME" "$STORY_COUNT"

# Validate output
validate_output "$SPEC_DIR"

# Print summary
print_summary "$FR_COUNT" "$NFR_COUNT" "$STORY_COUNT" "$ARCH_COUNT"
