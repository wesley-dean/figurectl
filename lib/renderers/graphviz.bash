# shellcheck shell=bash
## @file lib/renderers/graphviz.bash
## @brief Renders materialized DOT figures through Graphviz.
## @details
## This explicitly ordered renderer is shared by the built-in SVG and PNG output
## plugins.  Output plugins register this function by name; the core orchestrator
## invokes the registered function without maintaining a format-name dispatch
## table.
##
## Caller-provided DOT/style content is passed as data to AWK and Graphviz, never
## evaluated as Bash source.  Graphviz remains a conditional native-code runtime
## dependency with the authority of the figurectl process; `doc/threat-model.md`
## records that residual trust boundary.
##
## The DOT-style transformer is embedded into generated artifacts during build.
## `figurectl_dot_style_awk_write()` is therefore expected to exist by the time a
## render is requested even though its generated definition may appear later in
## the assembled Bash file than this maintained function definition.

## @fn figurectl_render_graphviz()
## @brief Converts materialized DOT files to one registered graphical output.
## @details
## The render manifest contains paths emitted by the AWK render phase.  Non-DOT
## entries are ignored.  For each DOT entry, Graphviz writes a sibling file using
## the requested output extension.
##
## When `DOT_STYLE` is non-empty, the embedded DOT-style AWK program is written to
## a secure temporary file and used to produce a temporary styled DOT input under
## `FIGURES_DIR`.  Temporary path templates end in `XXXXXX` for compatibility
## with both GNU and BusyBox `mktemp`.  Both temporary files are removed after
## each render attempt.  The historical style behavior is preserved: style text
## is inserted after the first textual `{` in the DOT source.
##
## @param manifest Path containing materialized source asset paths, one per line.
## @param output_format Graphviz `-T` format and generated filename extension.
## @par Standard Output
## Nothing is written by figurectl on successful rendering.
## @par Standard Error
## Missing Graphviz, style-transform failure, and Graphviz failure are reported
## through `die()`.  Graphviz may also write renderer diagnostics.
## @par Side Effects
## Invokes AWK and Graphviz; may create temporary files and writes generated
## sibling graphics beside materialized DOT files.
## @retval 0 Every applicable manifest entry rendered successfully.
figurectl_render_graphviz() {
  local manifest=$1
  local output_format=$2
  local dot_file
  local render_input
  local style_awk_file
  local styled_dot_file
  local awk_status

  while IFS= read -r dot_file; do
    [[ $dot_file == *.dot ]] || continue

    command -v dot > /dev/null 2>&1 \
      || die "Graphviz 'dot' is required for ${output_format} output"

    render_input=$dot_file
    style_awk_file=''
    styled_dot_file=''

    if [[ -n $DOT_STYLE ]]; then
      style_awk_file=$(mktemp "${TMPDIR:-/tmp}/figurectl.dot-style.XXXXXX")
      figurectl_dot_style_awk_write "$style_awk_file"
      styled_dot_file=$(mktemp "${FIGURES_DIR}/.styled.XXXXXX")

      if awk \
        -v stylefile="$DOT_STYLE" \
        -f "$style_awk_file" \
        "$dot_file" > "$styled_dot_file"; then
        awk_status=0
      else
        awk_status=$?
      fi

      rm -f "$style_awk_file"
      style_awk_file=''

      if ((awk_status != 0)); then
        rm -f "$styled_dot_file"
        die "failed to apply DOT style to ${dot_file}"
      fi

      render_input=$styled_dot_file
    fi

    if ! dot \
      "-T${output_format}" \
      -o "${dot_file%.dot}.${output_format}" \
      "$render_input"; then
      [[ -z $styled_dot_file ]] || rm -f "$styled_dot_file"
      [[ -z $style_awk_file ]] || rm -f "$style_awk_file"
      die "Graphviz failed rendering ${dot_file##*/} as ${output_format}"
    fi

    [[ -z $styled_dot_file ]] || rm -f "$styled_dot_file"
    [[ -z $style_awk_file ]] || rm -f "$style_awk_file"
  done < "$manifest"
}
