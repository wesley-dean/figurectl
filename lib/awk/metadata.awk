## @file lib/awk/metadata.awk
## @brief Parses and validates figure metadata attributes.
## @details
## Figure metadata is carried in an HTML comment immediately preceding the
## authored fenced payload.  This module recognizes the compatibility-baseline
## attributes `id`, `format`, `alt`, and `caption`, rejects duplicate or unknown
## attributes, validates safe identifiers, and preserves the historical fallback
## behavior for missing identifiers and alternative text.
##
## Supported authored formats are supplied by the built-in format registry through
## the `source_ext` array populated by `capabilities.awk`; the parser therefore
## does not maintain a second hard-coded format inventory.  The module assumes
## `line0` identifies the first physical line of the current figure directive and
## updates the global current-figure fields used by later fence and action modules.
## The implementation targets portable AWK.

## @fn attr_count(s, key)
## @brief Counts quoted occurrences of one metadata attribute.
## @details
## Attribute names are matched only at the start of the metadata string or after
## whitespace.  Values must use double quotes, matching the historical grammar.
## The helper does not interpret escapes inside quoted values.
##
## @param s Metadata text to inspect.
## @param key Attribute name to count.
## @local t Remaining unexamined metadata text.
## @local re Dynamic regular expression for the requested key.
## @local n Number of matching attributes found.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The number of matching attributes.
function attr_count(s, key,    t, re, n) {
  t = s
  n = 0
  re = "(^|[[:space:]])" key \
       "[[:space:]]*=[[:space:]]*\"[^\"]*\""
  while (match(t, re)) {
    n++
    t = substr(t, RSTART + RLENGTH)
  }
  return n
}

## @fn attr_value(s, key)
## @brief Returns the quoted value of one metadata attribute.
## @details
## The helper applies the same attribute grammar as `attr_count()`.  The returned
## text excludes the attribute name, equals sign, surrounding whitespace, and
## double quotes.  An absent attribute yields the empty string.
##
## @param s Metadata text to inspect.
## @param key Attribute name whose value is requested.
## @local re Dynamic regular expression for the requested key.
## @local m Matched attribute fragment after extraction from the metadata.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The unquoted attribute value, or the empty string when absent.
function attr_value(s, key,    re, m) {
  re = "(^|[[:space:]])" key \
       "[[:space:]]*=[[:space:]]*\"[^\"]*\""
  if (!match(s, re)) {
    return ""
  }
  m = substr(s, RSTART, RLENGTH)
  sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*\"", "", m)
  sub("\"$", "", m)
  return m
}

## @fn strip_attrs(s)
## @brief Removes every recognized metadata attribute from a metadata string.
## @details
## Validation uses the remaining text to detect unrecognized tokens after all
## supported attributes have been removed.  The supported attribute inventory is
## intentionally fixed here because these are figure-directive metadata keys, not
## pluggable authored/output formats.
##
## @param s Metadata text from which recognized attributes are removed.
## @local keys Scratch array containing the supported attribute names.
## @local i Current attribute index.
## @local re Dynamic regular expression for the current attribute.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Remaining metadata text with surrounding whitespace removed.
function strip_attrs(s,    keys, i, re) {
  keys[1] = "id"
  keys[2] = "format"
  keys[3] = "alt"
  keys[4] = "caption"

  for (i = 1; i <= 4; i++) {
    re = "(^|[[:space:]])" keys[i] \
         "[[:space:]]*=[[:space:]]*\"[^\"]*\""
    while (match(s, re)) {
      s = substr(s, 1, RSTART - 1) " " \
          substr(s, RSTART + RLENGTH)
    }
  }
  return trim(s)
}

## @fn parse_attrs(meta)
## @brief Validates metadata and populates the current figure state.
## @details
## Exactly one `format` attribute is required.  `id`, `alt`, and `caption` may
## appear at most once.  The declared format must exist in the `source_ext`
## capability array populated from the built-in input registry.  Missing
## identifiers receive a format-local sequential name, while missing alternative
## text receives the generic `Technical figure` fallback; both recoveries emit
## warnings.
##
## Identifier validation occurs before the value can be used as a pathname.
## Duplicate detection is scoped by authored format so one text representation
## and one DOT representation may share the same conceptual figure identifier.
##
## @param meta Accumulated figure metadata excluding the comment delimiters.
## @local c Count of occurrences for the attribute currently being validated.
## @local left Unrecognized metadata remaining after supported attributes are
## removed.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Compatibility warnings are emitted for missing `id` or `alt`; invalid
## metadata is reported through `fail()`.
##
## @par Globals
## Reads `line0` and `source_ext`.  Sets `id`, `fmt`, `alt`, and `caption`.
## Updates `format_seen` and `seen` to implement fallback numbering and duplicate
## detection.
##
## @par Side Effects
## Invalid metadata terminates the AWK process through `fail()`.
##
## @returns No meaningful value; callers consume the populated global state.
function parse_attrs(meta,    c, left) {
  c = attr_count(meta, "id")
  if (c > 1) {
    fail("duplicate id attribute near line " line0)
  }
  if (c == 1) {
    id = attr_value(meta, "id")
  }

  c = attr_count(meta, "format")
  if (c != 1) {
    fail("figure beginning at line " line0 \
         " must contain exactly one format attribute")
  }
  fmt = attr_value(meta, "format")

  c = attr_count(meta, "alt")
  if (c > 1) {
    fail("duplicate alt attribute near line " line0)
  }
  if (c == 1) {
    alt = attr_value(meta, "alt")
  }

  c = attr_count(meta, "caption")
  if (c > 1) {
    fail("duplicate caption attribute near line " line0)
  }
  if (c == 1) {
    caption = attr_value(meta, "caption")
  }

  left = strip_attrs(meta)
  if (left != "") {
    fail("unrecognized figure metadata near line " line0 ": " left)
  }

  if (!(fmt in source_ext)) {
    fail("unsupported source format: " fmt)
  }

  format_seen[fmt]++
  if (id == "") {
    id = sprintf("figure-%03d", format_seen[fmt])
    warn("missing id; using " id)
  }

  if (id !~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
    fail("unsafe figure id: " id)
  }

  if (seen[fmt SUBSEP id]++) {
    fail("duplicate " fmt " figure id: " id)
  }

  if (alt == "") {
    alt = "Technical figure"
    warn("figure " id " is missing alt text")
  }
}
