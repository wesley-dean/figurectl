#!/usr/bin/env bash
## @file src/orchestrator.bash
## @brief Provides the maintained-source figurectl command-line orchestrator.
## @details
## This file is the behavior-preserving Bash extraction of
## `wesley-dean/writing/scripts/figurectl.bash`.  It retains the existing public
## `select`, `render`, `replace`, and `process` command behavior while moving the
## embedded AWK program into documented modules under `lib/awk/`.
##
## During this extraction phase, the orchestrator resolves those AWK modules from
## the maintained repository tree and invokes them with repeated `awk -f`
## arguments.  This is a development-source execution path, not the final
## distribution design.  ADR-018 requires the later build phase to embed the
## selected modules into standalone release artifacts without runtime source-tree
## discovery.
##
## Bash 4.3 is the compatibility floor.  The orchestrator uses portable AWK for
## Markdown processing and conditionally invokes Graphviz `dot` only for SVG or
## PNG rendering.  Caller-selected DOT styling remains external policy and is
## transformed by `lib/awk/dot-style.awk` before Graphviz execution.
##
## The source-module order below is explicit because the AWK modules form one
## program and later modules call functions defined by earlier responsibility
## layers.  This phase does not implement the generalized build-time input/output
## plugin discovery defined by ADR-018; that work remains isolated to the next
## implementation phase.

set -euo pipefail

## Absolute repository root used only by the maintained-source execution path.
FIGURECTL_SOURCE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

## Ordered AWK modules that together implement figure Markdown processing.
FIGURECTL_PROCESSOR_AWK_FILES=(
  "${FIGURECTL_SOURCE_ROOT}/lib/awk/common.awk"
  "${FIGURECTL_SOURCE_ROOT}/lib/awk/metadata.awk"
  "${FIGURECTL_SOURCE_ROOT}/lib/awk/fences.awk"
  "${FIGURECTL_SOURCE_ROOT}/lib/awk/actions.awk"
  "${FIGURECTL_SOURCE_ROOT}/lib/awk/main.awk"
)

## AWK program that injects caller-owned Graphviz style defaults.
FIGURECTL_DOT_STYLE_AWK="${FIGURECTL_SOURCE_ROOT}/lib/awk/dot-style.awk"

## @fn usage()
## @brief Prints the figurectl compatibility-baseline command-line usage.
## @details
## The usage surface intentionally matches the writing-repository implementation
## during extraction.  Public CLI changes are outside this phase.
##
## @par Standard Output
## The supported commands, options, formats, and standard-input default.
## @retval 0 Usage text was printed.
usage() {
  cat << 'USAGE'
Usage:
  figurectl.bash select  --format FORMAT [INPUT]
  figurectl.bash render  --format FORMAT --figures-dir DIR [--dot-style FILE] [INPUT]
  figurectl.bash replace --format FORMAT --figures-dir DIR [--link-prefix PATH] [INPUT]
  figurectl.bash process --format FORMAT --figures-dir DIR [--dot-style FILE] [--link-prefix PATH] [--output FILE] [INPUT]

Formats: text, dot, svg, png
INPUT defaults to standard input.
USAGE
}

## @fn die_usage()
## @brief Reports invalid command-line usage and terminates figurectl.
## @details
## Invalid invocation is a distinct compatibility category from runtime failure.
## The diagnostic and usage text are written to standard error before the process
## exits with status 2.
##
## @param message Human-readable invalid-usage diagnostic.
## @par Standard Error
## Writes the prefixed diagnostic followed by complete usage text.
## @par Exit Status
## Terminates the figurectl process with status 2.
die_usage() {
  printf 'figurectl: %s\n' "$1" >&2
  usage >&2
  exit 2
}

## @fn die()
## @brief Reports a runtime failure and terminates figurectl.
## @details
## Runtime failures include missing input files, unavailable Graphviz, invalid
## style resources, and Graphviz rendering failure.  Parser/figure syntax errors
## remain status 2 because they originate from the AWK processor's validation
## contract.
##
## @param message Human-readable runtime-failure diagnostic.
## @par Standard Error
## Writes one prefixed diagnostic line.
## @par Exit Status
## Terminates the figurectl process with status 1.
die() {
  printf 'figurectl: %s\n' "$1" >&2
  exit 1
}

## @fn source_format_for_output()
## @brief Maps one requested output format to its required authored source.
## @details
## Text output consumes text source.  DOT, SVG, and PNG output consume DOT source.
## The mapping is the v1 compatibility contract defined by ADR-017 and the public
## specification.
##
## @param format Requested output format.
## @par Standard Output
## Writes `text` or `dot` for a supported output format.
## @retval 0 The requested format is supported and its source was printed.
## @retval 1 The requested format is unsupported.
source_format_for_output() {
  case "$1" in
    text) printf '%s\n' text ;;
    dot | svg | png) printf '%s\n' dot ;;
    *) return 1 ;;
  esac
}

## @fn parse_common_args()
## @brief Parses the shared compatibility-baseline figurectl options.
## @details
## The parser resets all command option globals on each invocation and accepts
## the same shared option inventory as the original script, including options
## that an individual subcommand may not use.  At most one input pathname is
## accepted.  `--` terminates option parsing and may be followed by that one
## pathname.
##
## The function requires `--format` and validates it through
## `source_format_for_output()`.  Subcommand-specific requirements such as
## `--figures-dir` are enforced by the command functions after this shared parse.
##
## @param ... Command-specific arguments after the top-level command name.
## @par Standard Output
## Nothing is written during successful parsing.
## @par Standard Error
## Invalid input is reported by `die_usage()` together with usage text.
## @par Side Effects
## Sets global `FORMAT`, `FIGURES_DIR`, `DOT_STYLE`, `LINK_PREFIX`, `OUTPUT`, and
## `INPUT`.
## @retval 0 Arguments were parsed and the requested format is supported.
parse_common_args() {
  FORMAT=''
  FIGURES_DIR=''
  DOT_STYLE=''
  LINK_PREFIX=''
  OUTPUT=''
  INPUT='-'

  while (($#)); do
    case "$1" in
      --format)
        (($# >= 2)) || die_usage '--format requires a value'
        FORMAT=$2
        shift 2
        ;;
      --figures-dir)
        (($# >= 2)) || die_usage '--figures-dir requires a value'
        FIGURES_DIR=$2
        shift 2
        ;;
      --dot-style)
        (($# >= 2)) || die_usage '--dot-style requires a value'
        DOT_STYLE=$2
        shift 2
        ;;
      --link-prefix)
        (($# >= 2)) || die_usage '--link-prefix requires a value'
        LINK_PREFIX=$2
        shift 2
        ;;
      --output)
        (($# >= 2)) || die_usage '--output requires a value'
        OUTPUT=$2
        shift 2
        ;;
      --)
        shift
        if (($# > 1)); then
          die_usage 'at most one input path may be supplied'
        fi
        (($# == 0)) || INPUT=$1
        shift $(($# > 0 ? 1 : 0))
        ;;
      -*)
        die_usage "unknown option: $1"
        ;;
      *)
        [[ $INPUT == '-' ]] \
          || die_usage 'at most one input path may be supplied'
        INPUT=$1
        shift
        ;;
    esac
  done

  [[ -n $FORMAT ]] || die_usage '--format is required'
  source_format_for_output "$FORMAT" > /dev/null \
    || die_usage "unsupported format: $FORMAT"
}

## @fn input_path_for_awk()
## @brief Resolves the configured input into the pathname passed to AWK.
## @details
## The historical implementation represents standard input as `/dev/stdin`.
## Named input must already exist as a regular file.  This extraction preserves
## that behavior rather than changing the input abstraction.
##
## @par Standard Output
## Writes `/dev/stdin` or the validated configured input pathname.
## @par Standard Error
## A missing named input is reported through `die()`.
## @retval 0 The AWK input pathname was written successfully.
input_path_for_awk() {
  if [[ $INPUT == '-' ]]; then
    printf '%s\n' /dev/stdin
  else
    [[ -f $INPUT ]] || die "input does not exist: $INPUT"
    printf '%s\n' "$INPUT"
  fi
}

## @fn run_awk_mode()
## @brief Executes the modular figure processor in one public phase mode.
## @details
## Every processor AWK module is passed to the selected AWK implementation with a
## separate `-f` argument in explicit source order.  Configuration is supplied
## through `-v` exactly as it was supplied to the embedded compatibility program.
## The modular source files therefore behave as one AWK program without requiring
## concatenation during development.
##
## @param mode Processing mode: `select`, `render`, or `replace`.
## @par Standard Output
## Carries the selected Markdown, render manifest, or replacement Markdown for
## the requested mode.
## @par Standard Error
## Carries AWK validation diagnostics and compatibility warnings.
## @retval 0 The AWK phase completed successfully.
## @retval 2 The AWK processor rejected malformed or inconsistent figure input.
run_awk_mode() {
  local mode=$1
  local input_path
  local source_file
  local -a awk_args=()

  input_path=$(input_path_for_awk)
  for source_file in "${FIGURECTL_PROCESSOR_AWK_FILES[@]}"; do
    awk_args+=(-f "$source_file")
  done

  awk \
    -v mode="$mode" \
    -v want="$FORMAT" \
    -v wantsrc="$(source_format_for_output "$FORMAT")" \
    -v figdir="$FIGURES_DIR" \
    -v linkprefix="$LINK_PREFIX" \
    "${awk_args[@]}" \
    "$input_path"
}

## @fn render_graphics()
## @brief Renders materialized DOT files to the requested graphical format.
## @details
## The render manifest contains paths produced by the AWK `render` phase.  Only
## `.dot` entries participate in graphical rendering.  SVG and PNG rendering
## require Graphviz `dot`; text and DOT output return without invoking Graphviz.
##
## When `DOT_STYLE` is configured, `lib/awk/dot-style.awk` writes a temporary
## styled DOT file beneath `FIGURES_DIR`.  The temporary file is removed on both
## successful rendering and handled failures.  Caller-provided style text is not
## interpreted by Bash; it is inserted into DOT input before Graphviz receives it.
##
## @param manifest Path containing one materialized asset pathname per line.
## @par Standard Output
## Graphviz output is directed to generated files rather than standard output.
## @par Standard Error
## Missing Graphviz, style-transformation failure, and Graphviz failure are
## reported through `die()`.  Graphviz may also write its own diagnostics.
## @par Side Effects
## May create temporary styled DOT input and generated `.svg` or `.png` files.
## Invokes AWK and Graphviz as external commands.
## @retval 0 No graphical rendering was required, or all rendering succeeded.
render_graphics() {
  local manifest=$1
  [[ $FORMAT == svg || $FORMAT == png ]] || return 0

  local dot_file render_input temp_file
  while IFS= read -r dot_file; do
    [[ $dot_file == *.dot ]] || continue
    command -v dot > /dev/null 2>&1 \
      || die "Graphviz 'dot' is required for $FORMAT output"

    render_input=$dot_file
    temp_file=''

    if [[ -n $DOT_STYLE ]]; then
      temp_file=$(mktemp "${FIGURES_DIR}/.styled.XXXXXX.dot")
      awk \
        -v stylefile="$DOT_STYLE" \
        -f "$FIGURECTL_DOT_STYLE_AWK" \
        "$dot_file" > "$temp_file" || {
        rm -f "$temp_file"
        die "failed to apply DOT style to ${dot_file}"
      }
      render_input=$temp_file
    fi

    if ! dot "-T${FORMAT}" -o "${dot_file%.dot}.${FORMAT}" "$render_input"; then
      [[ -z $temp_file ]] || rm -f "$temp_file"
      die "Graphviz failed rendering ${dot_file##*/} as ${FORMAT}"
    fi

    [[ -z $temp_file ]] || rm -f "$temp_file"
  done < "$manifest"
}

## @fn command_select()
## @brief Executes source-representation selection.
## @details
## Shared arguments are parsed, then the `select` AWK mode emits ordinary
## Markdown plus only the figure source representation required by the requested
## output format.
##
## @param ... Arguments accepted by the public `select` command.
## @par Standard Output
## Selected Markdown is written to standard output.
## @retval 0 Selection completed successfully.
## @retval 2 Usage or figure syntax was invalid.
command_select() {
  parse_common_args "$@"
  run_awk_mode select
}

## @fn command_render()
## @brief Materializes selected source figures and renders graphics when needed.
## @details
## `--figures-dir` is mandatory.  The directory is created when absent.  A
## configured DOT style must already exist even when later work would not use it,
## preserving the baseline validation order.  The render manifest is temporary
## process state and is removed through an EXIT trap on interruption or failure.
##
## @param ... Arguments accepted by the public `render` command.
## @par Standard Output
## Successful rendering normally produces no final standard output; the internal
## AWK manifest is redirected to a temporary file.
## @par Side Effects
## Creates the figures directory, materialized figure assets, optional graphics,
## and a temporary render manifest.
## @retval 0 Rendering completed successfully.
command_render() {
  parse_common_args "$@"
  [[ -n $FIGURES_DIR ]] || die_usage '--figures-dir is required for render'
  mkdir -p "$FIGURES_DIR"
  if [[ -n $DOT_STYLE && ! -f $DOT_STYLE ]]; then
    die "DOT style file does not exist: $DOT_STYLE"
  fi

  local manifest
  manifest=$(mktemp "${TMPDIR:-/tmp}/figurectl.render.XXXXXX")
  trap 'rm -f "$manifest"' EXIT
  run_awk_mode render > "$manifest"
  render_graphics "$manifest"
  rm -f "$manifest"
  trap - EXIT
}

## @fn command_replace()
## @brief Replaces selected figure directives with ordinary publication Markdown.
## @details
## Replacement consumes assets already materialized beneath `--figures-dir`.
## Graphical references use `--link-prefix` when supplied and otherwise use the
## figure directory path.
##
## @param ... Arguments accepted by the public `replace` command.
## @par Standard Output
## Replacement Markdown is written to standard output.
## @retval 0 Replacement completed successfully.
## @retval 2 Usage or figure syntax was invalid.
command_replace() {
  parse_common_args "$@"
  [[ -n $FIGURES_DIR ]] || die_usage '--figures-dir is required for replace'
  run_awk_mode replace
}

## @fn command_process()
## @brief Executes the complete select, render, and replace pipeline.
## @details
## The command creates temporary selected-Markdown and render-manifest files,
## runs each public phase in order, conditionally renders Graphviz output, and
## writes final Markdown to `OUTPUT` when configured or standard output otherwise.
##
## After selection, global `INPUT` is intentionally rebound to the temporary
## selected Markdown so render and replace consume exactly the selected source.
## This mirrors the original implementation's physical three-pass pipeline.
##
## @param ... Arguments accepted by the public `process` command.
## @par Standard Output
## Final Markdown is written here when `--output` is omitted.
## @par Side Effects
## Creates the figures directory, selected/render temporary files, materialized
## figure assets, optional graphics, and the requested output file when supplied.
## @retval 0 The complete pipeline completed successfully.
command_process() {
  parse_common_args "$@"
  [[ -n $FIGURES_DIR ]] || die_usage '--figures-dir is required for process'
  mkdir -p "$FIGURES_DIR"
  if [[ -n $DOT_STYLE && ! -f $DOT_STYLE ]]; then
    die "DOT style file does not exist: $DOT_STYLE"
  fi

  local selected manifest
  selected=$(mktemp "${TMPDIR:-/tmp}/figurectl.selected.XXXXXX")
  manifest=$(mktemp "${TMPDIR:-/tmp}/figurectl.render.XXXXXX")
  trap 'rm -f "$selected" "$manifest"' EXIT

  run_awk_mode select > "$selected"

  INPUT=$selected
  run_awk_mode render > "$manifest"
  render_graphics "$manifest"

  if [[ -n $OUTPUT ]]; then
    run_awk_mode replace > "$OUTPUT"
  else
    run_awk_mode replace
  fi

  rm -f "$selected" "$manifest"
  trap - EXIT
}

## @fn main()
## @brief Dispatches the public figurectl command surface.
## @details
## A command is required.  `help`, `-h`, and `--help` print usage without
## requiring a format.  All other recognized commands delegate to their phase
## functions; unknown commands are invalid usage.
##
## @param ... Complete command-line arguments supplied to the source runner.
## @retval 0 The requested operation completed successfully.
## @retval 1 A runtime dependency, file, style, or Graphviz operation failed.
## @retval 2 Command usage or figure syntax was invalid.
main() {
  (($# > 0)) || die_usage 'missing command'
  local command=$1
  shift

  case "$command" in
    select) command_select "$@" ;;
    render) command_render "$@" ;;
    replace) command_replace "$@" ;;
    process) command_process "$@" ;;
    help | -h | --help) usage ;;
    *) die_usage "unknown command: $command" ;;
  esac
}

main "$@"
