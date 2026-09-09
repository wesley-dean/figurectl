## @file lib/awk/fences.awk
## @brief Recognizes figure payload fences and validates source information.
## @details
## Figure payloads use ordinary Markdown fenced code blocks.  This module
## preserves the compatibility-baseline behavior for backtick and tilde fences,
## fences longer than three characters, and information-string validation against
## the source format declared in figure metadata.
##
## The functions operate on the current figure globals populated by
## `parse_attrs()`.  They do not consume records directly and target portable AWK.

## @fn parse_open_fence(line)
## @brief Validates and records the opening fence for the current figure.
## @details
## Leading whitespace is ignored before fence recognition.  The first fence
## character must be a backtick or tilde, and its opening run must be at least
## three characters.  The first token after the fence must exactly match the
## current figure's declared source format; disagreement is a processing error.
##
## On success, the function records the fence character and opening length in
## global state for later closing-fence recognition.
##
## @param line Candidate opening-fence line.
## @local s Working copy after leading whitespace is removed.
## @local ch Candidate fence character.
## @local n Length of the opening fence run.
## @local rest Information-string text after the opening fence.
## @local a Scratch array receiving information-string tokens.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A format mismatch is reported through `fail()`.
##
## @par Globals
## Reads `fmt` and `id`.  On success, sets `fence_char` and `fence_len`.
##
## @returns 1 when the line is a valid opening fence; otherwise 0.
## @retval 1 The opening fence is valid for the current figure.
## @retval 0 The line is not a recognized Markdown opening fence.
function parse_open_fence(line,    s, ch, n, rest, a) {
  s = line
  sub(/^[[:space:]]*/, "", s)
  ch = substr(s, 1, 1)

  if (ch != "`" && ch != "~") {
    return 0
  }

  n = count_leading(s, ch)
  if (n < 3) {
    return 0
  }

  rest = trim(substr(s, n + 1))
  split(rest, a, /[[:space:]]+/)
  if (a[1] != fmt) {
    fail("figure " id " declares format " fmt \
         " but fence uses " \
         (a[1] == "" ? "no information string" : a[1]))
  }

  fence_char = ch
  fence_len = n
  return 1
}

## @fn is_close_fence(line)
## @brief Reports whether a line closes the current figure payload fence.
## @details
## A closing fence must use the opening fence character, contain at least the
## opening fence length, and contain no non-whitespace content after the run.
## This preserves the historical relationship between opening and closing fences.
##
## @param line Candidate closing-fence line.
## @local s Working copy after leading whitespace is removed.
## @local n Length of the candidate closing fence run.
## @local rest Text following the candidate closing fence.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @par Globals
## Reads `fence_char` and `fence_len` established by `parse_open_fence()`.
##
## @returns 1 when the line closes the current fence; otherwise 0.
## @retval 1 The line is a valid closing fence.
## @retval 0 The line does not close the current fence.
function is_close_fence(line,    s, n, rest) {
  s = line
  sub(/^[[:space:]]*/, "", s)
  n = count_leading(s, fence_char)
  if (n < fence_len) {
    return 0
  }

  rest = trim(substr(s, n + 1))
  return rest == ""
}
