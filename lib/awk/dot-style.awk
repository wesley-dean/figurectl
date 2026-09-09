## @file lib/awk/dot-style.awk
## @brief Injects caller-supplied Graphviz defaults into a DOT source stream.
## @details
## Graphviz styling is caller-owned policy rather than figurectl semantics.  This
## small portable-AWK transformer preserves the historical behavior used by the
## writing repository: read the complete style resource named by `stylefile`,
## insert it immediately after the first textual `{` in the DOT input, pass all
## other records through unchanged, and fail when no insertion point is found.
##
## The Bash orchestrator invokes this program only when `--dot-style` is supplied
## for SVG or PNG rendering.  The style file is read with redirected `getline` and
## therefore does not consume records from the DOT input stream.

## @rule load_dot_style
## @brief Reads the caller-selected style resource before DOT input processing.
## @details
## Each style-file record is accumulated with the active `ORS`, matching the
## original inline AWK implementation.  The redirected input is explicitly
## closed after loading.  The caller validates that the style path exists before
## invoking this program.
##
## @par Trigger
## Runs once during BEGIN processing before the first DOT input record is read.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written directly to STDERR.
## @par Side Effects
## Reads the file named by global `stylefile`, stores its contents in global
## `style`, and closes the redirected input stream.
BEGIN {
  while ((getline line < stylefile) > 0) {
    style = style line ORS
  }
  close(stylefile)
}

## @rule insert_dot_style
## @brief Inserts loaded style text after the first opening brace in DOT input.
## @details
## The first input record containing `{` is split at the first occurrence.  The
## portion through the brace is printed, followed by the complete style text, and
## then any remaining content from the original record.  Later records bypass
## this rule because global `inserted` is set after the first insertion.
##
## This rule is intentionally textual rather than a DOT parser.  That limitation
## is part of the compatibility baseline and is not repaired during extraction.
##
## @par Trigger
## Runs for the first DOT input record containing `{` while `inserted` is false.
## @par Record Context
## Reads `$0` and does not modify `$0`, numbered fields, or `NF`.
## @par STDOUT
## Writes the split DOT record with the loaded style inserted after the first
## opening brace.
## @par STDERR
## Nothing is written to STDERR.
## @par Side Effects
## Sets global `inserted` to 1 and uses `next` so the pass-through rule does not
## emit the same record again.
!inserted && index($0, "{") {
  pos = index($0, "{")
  print substr($0, 1, pos)
  printf "%s", style
  if (length(substr($0, pos + 1))) {
    print substr($0, pos + 1)
  }
  inserted = 1
  next
}

## @rule pass_through_dot
## @brief Passes DOT records through unchanged after style insertion.
## @details
## Records that did not trigger the insertion rule, including all records after
## insertion, are emitted exactly once using ordinary AWK `print` behavior.
##
## @par Trigger
## Runs for every DOT input record not consumed by the insertion rule.
## @par Record Context
## Reads `$0` and does not modify the current record.
## @par STDOUT
## Writes the current DOT record followed by `ORS`.
## @par STDERR
## Nothing is written to STDERR.
{
  print
}

## @rule validate_dot_style_insertion
## @brief Fails when the DOT stream contained no textual opening brace.
## @details
## The Bash orchestrator translates this nonzero AWK status into the established
## `failed to apply DOT style` figurectl diagnostic.  The exact status 3 is an
## internal compatibility detail of this transformer rather than the public
## figurectl process status, which the orchestrator normalizes to 1.
##
## @par Trigger
## Runs once during END processing after DOT input processing completes.
## @par STDOUT
## Nothing is written directly to STDOUT.
## @par STDERR
## Nothing is written directly to STDERR.
## @par Side Effects
## Calls `exit 3` when global `inserted` is false.
END {
  if (!inserted) {
    exit 3
  }
}
