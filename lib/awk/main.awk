## @file lib/awk/main.awk
## @brief Drives the Markdown figure-processing state machine.
## @details
## This module owns the record-processing rules that recognize figure metadata,
## collect the immediately following fenced payload, and hand complete figures to
## the phase action layer.  It preserves the exact state transitions used by the
## writing-repository compatibility baseline: `normal`, `meta`, `gap`, and
## `payload`.
##
## The program consumes ordinary AWK input records.  It assumes the Bash
## orchestrator has supplied `mode`, `wantsrc`, `wantkind`, `wantext`, `wantinfo`,
## `source_spec`, `figdir`, and `linkprefix` with `-v`.  It targets portable AWK
## and does not modify `FS`, `RS`, `OFS`, or `ORS`.
##
## Ordinary Markdown is emitted unchanged in `select` and `replace` modes.  The
## `render` mode suppresses ordinary Markdown because its data channel is the list
## of materialized asset paths.  Figure payload bytes remain outside the metadata
## HTML comment, so payload text containing `-->` is treated as ordinary fenced
## content rather than comment syntax.

## @rule initialize_processor
## @brief Initializes source capabilities and figure-parser state.
## @details
## `source_spec` is trusted build-selected capability metadata supplied by the
## Bash registry.  `load_source_spec()` validates and materializes that inventory
## before any caller-controlled Markdown is parsed.  The state machine then starts
## in `normal`, where records pass through until a recognized figure metadata
## comment begins.
##
## @par Trigger
## Runs once during BEGIN processing before the first input record is read.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Malformed source capability metadata is reported through `fail()`.
## @par Side Effects
## Populates `source_ext` and sets the global `state` value to `normal`.
BEGIN {
  load_source_spec(source_spec)
  state = "normal"
}

## @rule process_markdown_record
## @brief Processes one Markdown record according to the current parser state.
## @details
## In `normal` state, the rule recognizes metadata comments whose first
## non-whitespace content begins with `<!-- figure`.  A recognized directive may
## end on that record or continue across later records.  Non-figure Markdown is
## passed through unless the processor is in `render` mode.
##
## In `meta` state, records are appended to both the raw figure representation
## and accumulated metadata until `-->` is encountered.  Text after the closing
## marker is rejected rather than interpreted as Markdown on the same line.
##
## In `gap` state, blank records between metadata and the fenced payload are
## preserved in the raw representation.  The first nonblank record must be a
## valid opening fence whose information string agrees with the declared source
## format.
##
## In `payload` state, every record is preserved in the raw representation.  A
## valid closing fence completes the figure and invokes `finish_figure()`;
## otherwise the record is appended to the payload using the historical
## newline-accumulation behavior.  This rule deliberately does not normalize or
## repair payload whitespace during the compatibility migration.
##
## @par Trigger
## Runs once for every ordinary input record.
## @par Record Context
## Reads `$0` and `NR`.  It does not modify `$0`, numbered fields, or `NF`.
## @par STDOUT
## Ordinary Markdown is printed in non-render modes.  Completed figures may
## produce mode-specific output through `finish_figure()`.
## @par STDERR
## Malformed directives, invalid metadata, fence mismatches, and invalid figure
## state are reported through helper functions that write to STDERR.
## @par Side Effects
## Updates parser globals including `state`, `line0`, `raw`, `meta`, `payload`,
## and the current figure fields.  May terminate processing through `fail()`.
{
  line = $0

  if (state == "normal") {
    if (match(line, /^[[:space:]]*<!--[[:space:]]*figure([[:space:]]|$)/)) {
      state = "meta"
      line0 = NR
      raw = line ORS
      part = substr(line, RSTART + RLENGTH)
      pos = index(part, "-->")

      if (pos) {
        meta = substr(part, 1, pos - 1)
        trail = trim(substr(part, pos + 3))
        if (trail != "") {
          fail("unexpected content after figure directive near line " NR)
        }
        parse_attrs(meta)
        state = "gap"
      } else {
        meta = part
      }
      next
    }

    if (mode != "render") {
      print line
    }
    next
  }

  if (state == "meta") {
    raw = raw line ORS
    pos = index(line, "-->")
    if (pos) {
      part = substr(line, 1, pos - 1)
      meta = meta " " part
      trail = trim(substr(line, pos + 3))
      if (trail != "") {
        fail("unexpected content after figure directive near line " NR)
      }
      parse_attrs(meta)
      state = "gap"
    } else {
      meta = meta " " line
    }
    next
  }

  if (state == "gap") {
    if (trim(line) == "") {
      raw = raw line ORS
      next
    }

    if (!parse_open_fence(line)) {
      fail("figure " id " is not followed by a fenced " fmt " block")
    }
    raw = raw line ORS
    state = "payload"
    next
  }

  if (state == "payload") {
    raw = raw line ORS
    if (is_close_fence(line)) {
      finish_figure()
      next
    }

    if (payload != "") {
      payload = payload ORS line
    } else {
      payload = line
    }
    next
  }
}

## @rule validate_final_state
## @brief Rejects incomplete figure constructs at end of input.
## @details
## A normally completed input stream must end in `normal` state.  When a prior
## fatal error has already initiated process termination, the global `fatal` flag
## suppresses duplicate diagnostics from this END rule.
##
## @par Trigger
## Runs once during END processing after ordinary input processing completes,
## subject to the AWK process's exit behavior.
## @par STDOUT
## Nothing is written directly to STDOUT.
## @par STDERR
## Writes one state-specific diagnostic through `fail()` when input ends inside
## an incomplete directive, gap, or payload.
## @par Side Effects
## May terminate the AWK process with status 2 through `fail()`.
END {
  if (!fatal) {
    if (state == "meta") {
      fail("unterminated figure directive beginning at line " line0)
    }
    if (state == "gap") {
      fail("figure " id " has no fenced payload")
    }
    if (state == "payload") {
      fail("figure " id " has an unterminated fenced payload")
    }
  }
}
