## @file lib/awk/actions.awk
## @brief Implements figure selection, materialization, and replacement actions.
## @details
## This module owns the phase-dependent actions performed after one complete
## figure directive and fenced payload have been parsed.  Format-specific
## capabilities arrive from the built-in Bash registry through AWK `-v` values
## and the `source_ext` array populated by `capabilities.awk`.
##
## The action layer therefore does not maintain its own text/DOT/SVG/PNG dispatch
## inventory.  It consumes the selected authored source, replacement kind,
## generated extension, and fenced information string supplied by the registered
## output implementation.  File paths are derived only from previously validated
## figure identifiers.  The implementation targets portable AWK.

## @fn emit_embedded(path, kind)
## @brief Re-emits a materialized source asset as a safe Markdown fence.
## @details
## The function reads the complete materialized asset from `path`, finds the
## longest run of backticks already present in its data, and emits a backtick
## fence at least one character longer.  The minimum output fence length is three.
## This prevents payload content from terminating the replacement fence.
##
## File input uses redirected `getline`; it does not consume the ordinary AWK
## input record stream.  The file is closed before the function returns.
##
## @param path Path of the materialized source asset to read.
## @param kind Information string to place after the generated opening fence.
## @local x Most recently read asset line.
## @local data Accumulated asset contents.
## @local n Required generated fence length.
## @local fence Generated backtick fence string.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Writes one fenced Markdown block containing the materialized asset.
## @par STDERR
## Nothing is written to STDERR.
##
## @par Side Effects
## Opens and reads `path`, then closes it before returning.
##
## @returns No meaningful value; the generated Markdown is written to STDOUT.
function emit_embedded(path, kind,    x, data, n, fence) {
  data = ""
  while ((getline x < path) > 0) {
    if (data != "") {
      data = data ORS
    }
    data = data x
  }
  close(path)

  n = max_run(data, "`") + 1
  if (n < 3) {
    n = 3
  }
  fence = repeat("`", n)

  print fence kind
  if (data != "") {
    print data
  }
  print fence
}

## @fn finish_figure()
## @brief Performs the selected phase action for one complete parsed figure.
## @details
## The function is called when the main record rule reaches a valid closing
## fence.  Empty payloads fail closed.  In `select` mode, the raw directive and
## payload are emitted only when the authored format equals `wantsrc`.  In
## `render` mode, the payload is materialized beneath `figdir` using the extension
## registered for that authored source.  In `replace` mode, `wantkind` selects a
## generic fenced-block or Markdown-image replacement path.
##
## The function assumes `id` has already passed safe filename validation in
## `parse_attrs()`.  It does not interpret source semantics or renderer behavior.
## After completing the action, it resets all current-figure globals so the state
## machine can resume ordinary Markdown processing.
##
## @local path Materialized source asset path used by render or replacement.
## @local link Markdown image target used by image replacement.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Depending on `mode`, writes selected raw Markdown, a rendered asset path, a
## replacement fenced block, an image reference, and optional caption.
## @par STDERR
## Invalid state or capability values are reported through `fail()`.
##
## @par Globals
## Reads `payload`, `mode`, `fmt`, `wantsrc`, `wantkind`, `wantext`, `wantinfo`,
## `source_ext`, `figdir`, `linkprefix`, `raw`, `id`, `alt`, and `caption`.
## Resets `state`, `raw`, `meta`, `payload`, `id`, `fmt`, `alt`, `caption`,
## `fence_char`, and `fence_len` after success.
##
## @par Side Effects
## Render mode writes and closes a materialized source asset beneath `figdir`.
## Fence replacement may read that asset through `emit_embedded()`.  Invalid or
## inconsistent mode/source/capability state terminates processing through
## `fail()`.
##
## @returns No meaningful value; behavior is expressed through streams, files,
## and state transitions.
function finish_figure(    path, link) {
  if (trim(payload) == "") {
    fail("figure " id " has empty payload")
  }

  if (mode == "select") {
    if (fmt == wantsrc) {
      printf "%s", raw
    }
  } else if (mode == "render") {
    if (fmt != wantsrc) {
      fail("render received unselected figure " id " with format " fmt)
    }
    if (!(fmt in source_ext)) {
      fail("render has no materialized extension for source format " fmt)
    }

    path = figdir "/" id "." source_ext[fmt]
    printf "%s", payload > path
    close(path)
    print path
  } else if (mode == "replace") {
    if (fmt != wantsrc) {
      fail("replace received unselected figure " id " with format " fmt)
    }
    if (!(fmt in source_ext)) {
      fail("replace has no materialized extension for source format " fmt)
    }

    if (wantkind == "fence") {
      if (wantinfo == "") {
        fail("fence output is missing an information string")
      }
      path = figdir "/" id "." source_ext[fmt]
      emit_embedded(path, wantinfo)
    } else if (wantkind == "image") {
      if (wantext == "") {
        fail("image output is missing an extension")
      }
      link = (linkprefix != "" ? linkprefix : figdir) "/" id "." wantext
      print "![" alt "](" link ")"
    } else {
      fail("unsupported replacement kind: " wantkind)
    }

    if (caption != "") {
      print ""
      print "*" caption "*"
    }
  }

  state = "normal"
  raw = ""
  meta = ""
  payload = ""
  id = ""
  fmt = ""
  alt = ""
  caption = ""
  fence_char = ""
  fence_len = 0
}
