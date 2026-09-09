## @file lib/awk/capabilities.awk
## @brief Loads build-selected source-format capabilities for the AWK processor.
## @details
## The Bash format registry serializes authored source capabilities as a
## semicolon-delimited `name=extension` string and passes it through `-v
## source_spec=...`.  This module converts that trusted artifact metadata into the
## `source_ext` associative array consumed by metadata validation and
## materialization.
##
## Registry names and extensions are validated by Bash before serialization, so
## `;` and `=` cannot appear inside tokens.  The AWK side still validates the
## serialized shape and duplicate names so malformed generated artifacts fail
## conservatively rather than silently changing behavior.
##
## The implementation targets portable AWK and performs no filesystem discovery.

## @fn load_source_spec(spec)
## @brief Parses the registered authored-source inventory into processor state.
## @details
## Each semicolon-delimited entry must contain exactly one source name and one
## materialized extension separated by `=`.  Empty specifications, malformed
## entries, and duplicate names are internal artifact defects reported through
## `fail()`.
##
## @param spec Semicolon-delimited `name=extension` capability specification.
## @local entries Scratch array containing serialized entries.
## @local parts Scratch array containing one entry's name and extension.
## @local count Number of serialized entries.
## @local part_count Number of fields in the current entry.
## @local i Current entry index.
## @local name Parsed source-format name.
## @local extension Parsed materialized extension.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Malformed artifact metadata is reported through `fail()`.
##
## @par Globals
## Populates the `source_ext` associative array.
##
## @par Side Effects
## Invalid capability metadata terminates the AWK process through `fail()`.
##
## @returns No meaningful value; callers consume `source_ext`.
function load_source_spec(spec,    entries, parts, count, part_count, i, name, extension) {
  if (spec == "") {
    fail("artifact contains no authored source formats")
  }

  count = split(spec, entries, ";")
  for (i = 1; i <= count; i++) {
    part_count = split(entries[i], parts, "=")
    if (part_count != 2 || parts[1] == "" || parts[2] == "") {
      fail("invalid authored source capability: " entries[i])
    }

    name = parts[1]
    extension = parts[2]
    if (name in source_ext) {
      fail("duplicate authored source capability: " name)
    }
    source_ext[name] = extension
  }
}
