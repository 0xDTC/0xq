#!/usr/bin/env bash
# parser.sh — Parse cheatsheet markdown files into a TSV index
# Sourced by q; expects Q_ROOT, Q_CACHE_DIR, Q_SHEETS_DIR from lib/core.sh

# ---------------------------------------------------------------------------
# q_build_index — Parse all .md files in Q_SHEETS_DIR and produce index.tsv
# ---------------------------------------------------------------------------
# TSV columns (tab-separated):
#   1 CATEGORY  — subdirectory name (recon, web, system, ...)
#   2 TOOL      — H1 heading (# Tool Name)
#   3 TITLE     — H2 heading (## Command Title)
#   4 DESCRIPTION — text between H2 and code block
#   5 COMMAND   — content of ```bash ... ``` block (multi-line joined by spaces)
#   6 RISK      — from <!-- meta: risk=X --> (default: low)
#   7 PHASE     — from <!-- meta: phase=X --> (default: misc)
#   8 TAGS      — merged file-level + entry-level tags (comma-separated)
#   9 SOURCE_FILE — path relative to Q_SHEETS_DIR
# ---------------------------------------------------------------------------
q_build_index() {
    local index_file="${Q_CACHE_DIR}/index.tsv"
    local sheets_dir="${Q_SHEETS_DIR}"

    # Collect all markdown files; bail if none found
    local -a md_files
    mapfile -t md_files < <(find "$sheets_dir" -name '*.md' -type f 2>/dev/null | sort)
    if [[ ${#md_files[@]} -eq 0 ]]; then
        q_warn "No cheatsheet files found in ${sheets_dir}"
        : > "$index_file"
        return 0
    fi

    # Run awk across all files, producing the TSV index
    awk -v sheets_dir="$sheets_dir" '
    # ------------------------------------------------------------------
    # Helper: trim leading/trailing whitespace
    # ------------------------------------------------------------------
    function trim(s) {
        gsub(/^[[:space:]]+/, "", s)
        gsub(/[[:space:]]+$/, "", s)
        return s
    }

    # ------------------------------------------------------------------
    # Helper: flush the current entry (if complete) as a TSV line
    # ------------------------------------------------------------------
    function flush_entry() {
        if (current_tool == "" || current_title == "") return

        # Trim accumulated fields
        desc = trim(description)
        cmd  = trim(command)

        # Defaults for risk / phase
        if (risk  == "") risk  = "low"
        if (phase == "") phase = "misc"

        # Merge file-level tags and entry-level tags
        merged_tags = ""
        if (file_tags != "" && entry_tags != "") {
            merged_tags = file_tags "," entry_tags
        } else if (file_tags != "") {
            merged_tags = file_tags
        } else {
            merged_tags = entry_tags
        }

        # Collapse any internal tabs/newlines in text fields
        gsub(/\t/, " ", desc)
        gsub(/\n/, " ", desc)
        gsub(/\t/, " ", cmd)
        gsub(/\n/, " ", cmd)
        # Collapse multiple spaces
        gsub(/  +/, " ", desc)
        gsub(/  +/, " ", cmd)

        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
            category, current_tool, current_title, desc, cmd, \
            risk, phase, merged_tags, source_file
    }

    # ------------------------------------------------------------------
    # Helper: reset per-entry state
    # ------------------------------------------------------------------
    function reset_entry() {
        current_title = ""
        description   = ""
        command       = ""
        risk          = ""
        phase         = ""
        entry_tags    = ""
        in_code_block = 0
        in_entry      = 0
    }

    # ------------------------------------------------------------------
    # On each new file, derive category and source_file, reset state
    # ------------------------------------------------------------------
    FNR == 1 {
        # Flush any trailing entry from previous file
        flush_entry()

        # Reset everything for the new file
        current_tool  = ""
        file_tags     = ""
        reset_entry()

        # Derive category and source_file by stripping sheets_dir prefix
        rel = FILENAME
        prefix = sheets_dir "/"
        if (index(rel, prefix) == 1) {
            rel = substr(rel, length(prefix) + 1)
        }
        n = split(rel, rparts, "/")
        category = (n > 1) ? rparts[1] : ""
        source_file = rel
    }

    # ------------------------------------------------------------------
    # File-level tags: <!-- tags: tag1, tag2 -->
    # ------------------------------------------------------------------
    /^<!--[[:space:]]*tags:/ && in_entry == 0 {
        s = $0
        gsub(/^<!--[[:space:]]*tags:[[:space:]]*/, "", s)
        gsub(/[[:space:]]*-->.*$/, "", s)
        gsub(/[[:space:]]+/, "", s)
        file_tags = s
        next
    }

    # ------------------------------------------------------------------
    # H1 heading — tool name (one per file)
    # ------------------------------------------------------------------
    /^# [^#]/ {
        s = $0
        sub(/^# +/, "", s)
        current_tool = trim(s)
        next
    }

    # ------------------------------------------------------------------
    # H2 heading — new command entry; flush any previous entry first
    # ------------------------------------------------------------------
    /^## / {
        flush_entry()
        reset_entry()

        s = $0
        sub(/^## +/, "", s)
        current_title = trim(s)
        in_entry = 1
        next
    }

    # ------------------------------------------------------------------
    # Code fence open: ```bash
    # ------------------------------------------------------------------
    /^```bash/ && in_entry == 1 {
        in_code_block = 1
        next
    }

    # ------------------------------------------------------------------
    # Code fence close: ``` (only when we are inside a code block)
    # ------------------------------------------------------------------
    /^```/ && in_code_block == 1 {
        in_code_block = 0
        next
    }

    # ------------------------------------------------------------------
    # Inside code block — accumulate command
    # ------------------------------------------------------------------
    in_code_block == 1 {
        line = $0
        if (command == "") {
            command = line
        } else {
            command = command " " line
        }
        next
    }

    # ------------------------------------------------------------------
    # Entry-level meta: <!-- meta: risk=low | phase=recon | tags=t1,t2 -->
    # ------------------------------------------------------------------
    /^<!--[[:space:]]*meta:/ && in_entry == 1 {
        s = $0
        gsub(/^<!--[[:space:]]*meta:[[:space:]]*/, "", s)
        gsub(/[[:space:]]*-->.*$/, "", s)
        # Split on |
        np = split(s, pairs, "[|]")
        for (p = 1; p <= np; p++) {
            kv = trim(pairs[p])
            eq = index(kv, "=")
            if (eq > 0) {
                k = trim(substr(kv, 1, eq - 1))
                v = trim(substr(kv, eq + 1))
                if (k == "risk")  risk = v
                if (k == "phase") phase = v
                if (k == "tags")  entry_tags = v
            }
        }
        next
    }

    # ------------------------------------------------------------------
    # Description text (between H2 and code block, skip blanks / HR)
    # ------------------------------------------------------------------
    in_entry == 1 && in_code_block == 0 {
        line = $0
        # Skip horizontal rules and blank lines at start
        if (line ~ /^---+$/) next
        if (line ~ /^>/) next   # skip blockquotes (tool description)
        line = trim(line)
        if (line == "") next
        if (description == "") {
            description = line
        } else {
            description = description " " line
        }
    }

    # ------------------------------------------------------------------
    # End of input — flush the last entry
    # ------------------------------------------------------------------
    END {
        flush_entry()
    }
    ' "${md_files[@]}" > "$index_file"

    local count
    count="$(wc -l < "$index_file")"
    q_info "Indexed ${count} commands from ${#md_files[@]} file(s)"
}

# ---------------------------------------------------------------------------
# q_rebuild_index — Unconditionally rebuild the index and update checksum
# ---------------------------------------------------------------------------
q_rebuild_index() {
    q_build_index

    # Store current checksum so q_ensure_index won't rebuild again
    local checksum
    checksum="$(_q_sheets_checksum)"
    printf '%s\n' "$checksum" > "${Q_CACHE_DIR}/checksum"
}

# ---------------------------------------------------------------------------
# q_ensure_index — Rebuild index only when cheatsheets have changed
# ---------------------------------------------------------------------------
q_ensure_index() {
    local checksum_file="${Q_CACHE_DIR}/checksum"
    local index_file="${Q_CACHE_DIR}/index.tsv"

    # Compute current checksum from file timestamps + names
    local current_checksum
    current_checksum="$(_q_sheets_checksum)"

    # Compare with stored checksum
    local stored_checksum=""
    if [[ -f "$checksum_file" ]]; then
        stored_checksum="$(<"$checksum_file")"
    fi

    if [[ "$current_checksum" != "$stored_checksum" ]] || [[ ! -f "$index_file" ]]; then
        q_info "Cheatsheets changed — rebuilding index..."
        q_build_index
        printf '%s\n' "$current_checksum" > "$checksum_file"
    fi
}

# ---------------------------------------------------------------------------
# _q_sheets_checksum — Compute a fingerprint of all .md files
# ---------------------------------------------------------------------------
_q_sheets_checksum() {
    # Use find -printf to avoid forking a separate stat process.
    # Single pipeline: find -printf is ~2ms vs find -exec stat ~6ms.
    find "$Q_SHEETS_DIR" -name '*.md' -printf '%T@\t%p\n' 2>/dev/null \
        | sort \
        | md5sum \
        | cut -d' ' -f1
}
