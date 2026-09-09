# shellcheck shell=bash
## @file src/orchestrator.bash
## @brief Provides the assembled figurectl command-line orchestrator.
## @details
## This file is the product-facing entry point appended after core Bash modules,
## build-discovered input/output plugins, and generated embedded-AWK writer
## functions.  It no longer discovers or reads maintained implementation files at
## runtime; generated artifacts contain every implementation they support.
##
## Build-time plugins populate the internal format registry before `main()` runs.
## The orchestrator asks that registry for requested-output capabilities and passes
## the selected authored-source/replacement metadata to the portable AWK processor.
## The processor itself is embedded literally during `make build`, materialized to
## a secure temporary file for each AWK invocation, and executed with `awk -f`.
##
## Bash 4.3 is the compatibility floor.  Graphviz `dot` remains conditional and is
## invoked only through a renderer function registered by graphical output
## plugins.  Caller-selected DOT styling remains external policy.

## @fn usage()
## @brief Prints the figurectl v1 command-line usage.
## @details
## The public format inventory is intentionally documented here rather than
## inferred from arbitrary runtime filesystem state.  The registry independently
## validates whether a requested output is present in the built artifact.
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
## Runtime failures include missing input files, unavailable renderer functions,
## missing Graphviz, invalid style resources, and renderer failure.  Parser/figure
## syntax errors remain status 2 because they originate from the AWK validation
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
## @brief Resolves one requested output through the built-in format registry.
## @param format Requested output format.
## @par Standard Output
## Writes the registered authored source name.
## @retval 0 The requested output is registered.
## @retval 1 The requested output is unsupported by this artifact.
source_format_for_output() {
  figurectl_output_source "$1"
}

## @fn parse_common_args()
## @brief Parses the shared compatibility-baseline figurectl options.
## @details
## The parser resets all command option globals on each invocation and accepts
## the same shared option inventory as the writing-repository implementation,
## including options that an individual subcommand may not use.  At most one
## input pathname is accepted.  `--` terminates option parsing and may be followed
## by that one pathname.
##
## The function requires `--format` and validates it against the implementations
## already assembled into the artifact.  Subcommand-specific requirements such as
## `--figures-dir` are enforced by command functions after the shared parse.
##
## @param ... Command-specific arguments after the top-level command name.
## @par Standard Output
## Nothing is written during successful parsing.
## @par Standard Error
## Invalid input is reported by `die_usage()` together with usage text.
## @par Side Effects
## Sets global `FORMAT`, `FIGURES_DIR`, `DOT_STYLE`, `LINK_PREFIX`, `OUTPUT`, and
## `INPUT`.
## @retval 0 Arguments were parsed and the requested output is registered.
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
  figurectl_output_supported "$FORMAT" \
    || die_usage "unsupported format: $FORMAT"
}

## @fn input_path_for_awk()
## @brief Resolves the configured input into the pathname passed to AWK.
## @details
## The compatibility implementation represents standard input as `/dev/stdin`.
## Named input must already exist as a regular file.
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
## @brief Executes the embedded figure processor in one public phase mode.
## @details
## `make build` concatenates the explicitly ordered AWK processor modules into the
## generated `figurectl_processor_awk_write()` function.  This helper writes those
## trusted bytes to a `mktemp` pathname, resolves selected-format capabilities from
## the already-initialized registry, executes portable AWK with `-f`, removes the
## temporary program, and returns the original AWK status.
##
## The source capability inventory is serialized as `name=extension` pairs by
## `figurectl_input_spec()`.  Registry token validation makes the serialization
## delimiters unambiguous before the AWK parser validates the generated metadata
## again.
##
## @param mode Processing mode: `select`, `render`, or `replace`.
## @par Standard Output
## Carries selected Markdown, the render manifest, or replacement Markdown for the
## requested mode.
## @par Standard Error
## Carries AWK validation diagnostics and compatibility warnings.
## @par Side Effects
## Creates and removes one temporary trusted AWK program file.
## @retval 0 The AWK phase completed successfully.
## @retval 2 The AWK processor rejected malformed or inconsistent figure input.
run_awk_mode() {
  local mode=$1
  local input_path
  local processor_awk
  local source_spec
  local wantsrc
  local wantkind
  local wantext
  local wantinfo
  local awk_status

  input_path=$(input_path_for_awk)
  processor_awk=$(mktemp "${TMPDIR:-/tmp}/figurectl.processor.XXXXXX.awk")

  if ! figurectl_processor_awk_write "$processor_awk"; then
    rm -f "$processor_awk"
    die 'failed to materialize embedded AWK processor'
  fi

  source_spec=$(figurectl_input_spec)
  wantsrc=$(figurectl_output_source "$FORMAT")
  wantkind=$(figurectl_output_kind "$FORMAT")
  wantext=$(figurectl_output_extension "$FORMAT")
  wantinfo=$(figurectl_output_fence_info "$FORMAT")

  if awk \
    -v mode="$mode" \
    -v wantsrc="$wantsrc" \
    -v wantkind="$wantkind" \
    -v wantext="$wantext" \
    -v wantinfo="$wantinfo" \
    -v source_spec="$source_spec" \
    -v figdir="$FIGURES_DIR" \
    -v linkprefix="$LINK_PREFIX" \
    -f "$processor_awk" \
    "$input_path"; then
    awk_status=0
  else
    awk_status=$?
  fi

  rm -f "$processor_awk"
  return "$awk_status"
}

## @fn render_registered_output()
## @brief Invokes the renderer registered for the requested output, when any.
## @details
## Fence outputs register no renderer and return immediately.  Graphical outputs
## register a trusted function name already assembled into the artifact.  Missing
## renderer functions are internal artifact defects; figurectl fails rather than
## searching the filesystem for an implementation.
##
## @param manifest Path containing materialized asset paths emitted by AWK.
## @par Standard Output
## Renderer-specific behavior; built-in Graphviz rendering writes files only.
## @par Standard Error
## Missing renderer functions and renderer failures are reported as runtime
## failures.
## @retval 0 No renderer was required, or the registered renderer succeeded.
render_registered_output() {
  local manifest=$1
  local renderer

  renderer=$(figurectl_output_renderer "$FORMAT")
  [[ -n $renderer ]] || return 0

  declare -F "$renderer" > /dev/null 2>&1 \
    || die "renderer unavailable for $FORMAT output: $renderer"

  "$renderer" "$manifest" "$FORMAT"
}

## @fn command_select()
## @brief Executes source-representation selection.
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
## @brief Materializes selected source figures and invokes a renderer when needed.
## @details
## `--figures-dir` is mandatory and created when absent.  A configured DOT style
## must already exist even when the requested output does not use it, preserving
## compatibility validation order.  The AWK render manifest is temporary process
## state and is removed through an EXIT trap on interruption or failure.
##
## @param ... Arguments accepted by the public `render` command.
## @par Standard Output
## Successful rendering normally produces no final standard output.
## @par Side Effects
## Creates the figures directory, materialized figure assets, optional rendered
## graphics, and a temporary render manifest.
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
  render_registered_output "$manifest"

  rm -f "$manifest"
  trap - EXIT
}

## @fn command_replace()
## @brief Replaces selected figure directives with publication Markdown.
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
## The command preserves the compatibility implementation's physical three-pass
## pipeline.  It creates temporary selected-Markdown and render-manifest files,
## runs each public phase in order, invokes the registered renderer when required,
## and writes final Markdown to `OUTPUT` or standard output.
##
## After selection, global `INPUT` is rebound to the temporary selected Markdown
## so render and replace consume exactly the selected authored representation.
##
## @param ... Arguments accepted by the public `process` command.
## @par Standard Output
## Final Markdown is written here when `--output` is omitted.
## @par Side Effects
## Creates the figures directory, selected/render temporary files, materialized
## assets, optional graphics, and the requested output file when supplied.
## @retval 0 The complete pipeline completed successfully.
command_process() {
  parse_common_args "$@"
  [[ -n $FIGURES_DIR ]] || die_usage '--figures-dir is required for process'
  mkdir -p "$FIGURES_DIR"
  if [[ -n $DOT_STYLE && ! -f $DOT_STYLE ]]; then
    die "DOT style file does not exist: $DOT_STYLE"
  fi

  local selected
  local manifest
  selected=$(mktemp "${TMPDIR:-/tmp}/figurectl.selected.XXXXXX")
  manifest=$(mktemp "${TMPDIR:-/tmp}/figurectl.render.XXXXXX")
  trap 'rm -f "$selected" "$manifest"' EXIT

  run_awk_mode select > "$selected"

  INPUT=$selected
  run_awk_mode render > "$manifest"
  render_registered_output "$manifest"

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
## @param ... Complete command-line arguments supplied to the generated artifact.
## @retval 0 The requested operation completed successfully.
## @retval 1 A runtime dependency, file, renderer, or Graphviz operation failed.
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
