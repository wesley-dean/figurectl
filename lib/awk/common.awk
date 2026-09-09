## @file lib/awk/common.awk
## @brief Provides shared helpers for the figure-processing AWK program.
## @details
## This module contains portable AWK helpers used by metadata parsing, fence
## recognition, rendering, and replacement.  It owns no record-processing rules
## and does not initialize the figure state machine.  The Bash orchestrator loads
## this file before the other processor modules so later modules may call these
## functions without duplicating low-level behavior.
##
## The implementation targets portable AWK.  It does not rely on GNU awk, mawk,
## or BusyBox-specific extensions.  Diagnostics use `/dev/stderr` to preserve the
## behavior of the writing-repository compatibility baseline.

## @fn trim(s)
## @brief Removes leading and trailing AWK whitespace from a string.
## @details
## The helper uses the portable `[[:space:]]` character class.  It does not
## modify internal whitespace and does not mutate caller-visible global state.
##
## @param s String to trim.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The trimmed string.
function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}

## @fn fail(msg)
## @brief Emits a figurectl diagnostic and terminates the AWK process.
## @details
## This is the processor's fail-closed path for malformed figure syntax and
## invalid processor state.  It sets the global `fatal` flag before terminating
## so the END rule does not emit a second state-machine diagnostic.
##
## The function terminates the AWK process with status 2, matching the historical
## figure parser's invalid-input behavior.
##
## @param msg Diagnostic text without the `figurectl:` prefix.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Writes one `figurectl:` diagnostic line.
##
## @par Globals
## Sets `fatal` to a nonzero value before process termination.
##
## @par Side Effects
## Calls `exit 2`, terminating the AWK program immediately.
##
## @returns No meaningful value; successful callers never regain control.
function fail(msg) {
  fatal = 1
  print "figurectl: " msg > "/dev/stderr"
  exit 2
}

## @fn warn(msg)
## @brief Emits a non-fatal figurectl compatibility warning.
## @details
## Warnings report recoverable metadata conditions such as generated identifiers
## and generic alternative text.  Processing continues after the diagnostic.
##
## @param msg Warning text without the `figurectl: warning:` prefix.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Writes one `figurectl: warning:` diagnostic line.
##
## @returns No meaningful value; callers must not depend on the return value.
function warn(msg) {
  print "figurectl: warning: " msg > "/dev/stderr"
}

## @fn repeat(ch, n)
## @brief Builds a string containing one character repeated a requested count.
## @details
## The helper is used when replacement output needs a Markdown fence longer than
## any backtick run already present in materialized figure content.
##
## @param ch Character or string fragment to repeat.
## @param n Number of repetitions, interpreted numerically.
## @local s Accumulated result string.
## @local i Loop counter.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The repeated string.
function repeat(ch, n,    s, i) {
  s = ""
  for (i = 0; i < n; i++) {
    s = s ch
  }
  return s
}

## @fn count_leading(s, ch)
## @brief Counts consecutive occurrences of a character at the start of text.
## @details
## Fence parsing uses this helper to determine the opening or closing fence
## length without depending on implementation-specific regular-expression
## capture facilities.
##
## @param s String to inspect.
## @param ch Character whose leading run is counted.
## @local n Number of consecutive matching characters seen so far.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The numeric length of the leading run.
function count_leading(s, ch,    n) {
  n = 0
  while (substr(s, n + 1, 1) == ch) {
    n++
  }
  return n
}

## @fn max_run(s, ch)
## @brief Finds the longest consecutive run of a character within a string.
## @details
## Replacement uses this value to select a Markdown backtick fence that cannot
## be terminated by backticks already present in the figure payload.
##
## @param s String to inspect.
## @param ch Character whose longest run is requested.
## @local i Current string index.
## @local n Length of the current run.
## @local m Longest run observed so far.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The numeric length of the longest run.
function max_run(s, ch,    i, n, m) {
  m = 0
  n = 0
  for (i = 1; i <= length(s); i++) {
    if (substr(s, i, 1) == ch) {
      n++
      if (n > m) {
        m = n
      }
    } else {
      n = 0
    }
  }
  return m
}
