#!/usr/bin/env bash
## @file scripts/build-artifact.bash
## @brief Assembles modular figurectl source into one documented Bash artifact.
## @details
## GNU Make invokes this build-only helper after calculating deterministic source
## lists and build provenance.  The helper concatenates explicitly ordered Bash
## core source, build-discovered input/output plugins, literal embedded AWK writer
## functions, and the product entry point into one `.dev.bash` artifact.
##
## Source-list arguments are whitespace-delimited by design.  ADR-004 establishes
## whitespace-free maintained source paths so ordinary Make lists remain
## inspectable; this helper preserves that contract rather than inventing another
## path serialization format.
##
## Embedded AWK uses quoted heredoc delimiters so `$`, backticks, backslashes,
## quotes, regular expressions, and shell-looking text remain literal when the
## generated artifact materializes its AWK program at runtime.  The helper rejects
## a source file containing a delimiter as an exact standalone line before writing
## output.  See `doc/threat-model.md` for the associated build-boundary analysis.

set -euo pipefail

PROCESSOR_AWK_DELIMITER='__FIGURECTL_PROCESSOR_AWK_8C3C6D1E__'
DOT_STYLE_AWK_DELIMITER='__FIGURECTL_DOT_STYLE_AWK_2A84F197__'

## @fn die()
## @brief Reports an artifact-assembly failure and terminates the build helper.
## @param message Human-readable build diagnostic.
## @par Standard Error
## Writes one prefixed diagnostic line.
## @par Exit Status
## Terminates with status 1.
die() {
  printf 'figurectl build: %s\n' "$1" >&2
  exit 1
}

## @fn require_file()
## @brief Verifies one maintained source path exists as a regular file.
## @param path Path to validate.
## @retval 0 The path identifies a regular file.
## @par Exit Status
## Terminates through `die()` when the path is missing.
require_file() {
  local path=$1
  [[ -f $path ]] || die "source file does not exist: $path"
}

## @fn split_source_list()
## @brief Splits one whitespace-delimited Make source list into a Bash array.
## @details
## The destination variable name must identify an array owned by this build
## helper.  `read -a` is used rather than `eval`, so source-list text is never
## interpreted as Bash code.
##
## @param value Whitespace-delimited source paths.
## @param destination Name of the destination Bash array.
## @retval 0 The list was split successfully.
split_source_list() {
  local value=$1
  local destination=$2
  local -a fields=()
  local field

  read -r -a fields <<< "$value"

  case "$destination" in
    core_sources)
      core_sources=("${fields[@]}")
      ;;
    input_plugin_sources)
      input_plugin_sources=("${fields[@]}")
      ;;
    output_plugin_sources)
      output_plugin_sources=("${fields[@]}")
      ;;
    processor_awk_sources)
      processor_awk_sources=("${fields[@]}")
      ;;
    *)
      die "unsupported source-list destination: $destination"
      ;;
  esac

  for field in "${fields[@]}"; do
    require_file "$field"
  done
}

## @fn emit_source_file()
## @brief Emits one maintained source file with a readable development marker.
## @details
## Marker comments aid inspection of `.dev.bash` and are intentionally removable
## by the ordinary artifact's full-line comment-stripping phase.
##
## @param path Maintained source file to emit.
## @par Standard Output
## Writes a begin marker, file bytes, a terminating newline, and an end marker.
## @retval 0 The source file was emitted.
emit_source_file() {
  local path=$1

  printf '\n# --- BEGIN %s ---\n' "$path"
  cat "$path"
  printf '\n# --- END %s ---\n' "$path"
}

## @fn validate_heredoc_delimiter()
## @brief Rejects AWK source that would collide with an embedding sentinel.
## @param delimiter Exact heredoc terminator to reserve.
## @param ... AWK source files to inspect.
## @retval 0 None of the sources contains the terminator as a standalone line.
## @par Exit Status
## Terminates through `die()` when a collision exists.
validate_heredoc_delimiter() {
  local delimiter=$1
  shift
  local path

  for path in "$@"; do
    require_file "$path"
    if grep -Fxq -- "$delimiter" "$path"; then
      die "AWK source collides with heredoc delimiter ${delimiter}: ${path}"
    fi
  done
}

## @fn emit_awk_writer()
## @brief Emits a Bash function that materializes concatenated AWK source.
## @details
## The generated function writes to its first pathname argument using a quoted
## heredoc.  Maintained AWK modules remain individually documented and reviewable,
## while the generated runtime program becomes one literal source stream.
##
## @param function_name Name of the generated Bash writer function.
## @param delimiter Reserved literal heredoc terminator.
## @param ... Ordered AWK source files to embed.
## @par Standard Output
## Writes one complete Bash function definition containing the AWK program.
## @retval 0 The generated writer function was emitted.
emit_awk_writer() {
  local function_name=$1
  local delimiter=$2
  shift 2
  local path

  validate_heredoc_delimiter "$delimiter" "$@"

  printf '\n%s() {\n' "$function_name"
  printf '%s\n' "  cat >\"\$1\" <<'${delimiter}'"

  for path in "$@"; do
    printf '# --- BEGIN %s ---\n' "$path"
    cat "$path"
    printf '\n# --- END %s ---\n' "$path"
  done

  printf '%s\n' "$delimiter"
  printf '}\n'
}

## @fn emit_provenance_header()
## @brief Writes the generated artifact shebang, provenance, and strict mode.
## @param project_name Logical project/artifact base name.
## @param version Build version.
## @param build_date Deterministic build timestamp/provenance value.
## @param build_commit Build commit provenance value.
## @param core_list Explicit Bash core source list.
## @param input_list Build-discovered input plugin list.
## @param output_list Build-discovered output plugin list.
## @param processor_list Explicit processor AWK source list.
## @param dot_style_source DOT-style AWK source path.
## @param entrypoint Product entrypoint source path.
## @par Standard Output
## Writes the artifact header and executable provenance assignments.
## @retval 0 The header was emitted.
emit_provenance_header() {
  local project_name=$1
  local version=$2
  local build_date=$3
  local build_commit=$4
  local core_list=$5
  local input_list=$6
  local output_list=$7
  local processor_list=$8
  local dot_style_source=$9
  local entrypoint=${10}

  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' '#'
  printf '%s\n' '# Generated by make build. Do not edit directly.'
  printf '# Project: %s\n' "$project_name"
  printf '# Version: %s\n' "$version"
  printf '# Build date: %s\n' "$build_date"
  printf '# Build commit: %s\n' "$build_commit"
  printf '# Core Bash source: %s\n' "$core_list"
  printf '# Discovered input plugins: %s\n' "$input_list"
  printf '# Discovered output plugins: %s\n' "$output_list"
  printf '# Processor AWK source: %s\n' "$processor_list"
  printf '# DOT style AWK source: %s\n' "$dot_style_source"
  printf '# Entrypoint: %s\n' "$entrypoint"
  printf '\nset -euo pipefail\n\n'
  printf 'FIGURECTL_PROJECT_NAME=%q\n' "$project_name"
  printf 'FIGURECTL_VERSION=%q\n' "$version"
  printf 'FIGURECTL_BUILD_DATE=%q\n' "$build_date"
  printf 'FIGURECTL_BUILD_COMMIT=%q\n' "$build_commit"
}

## @fn main()
## @brief Parses build inputs and writes the complete development artifact.
## @param output Temporary output pathname owned by Make.
## @param project_name Logical project name.
## @param version Build version.
## @param build_date Build date provenance.
## @param build_commit Build commit provenance.
## @param core_list Explicit Bash core source list.
## @param input_list Build-discovered input plugin list.
## @param output_list Build-discovered output plugin list.
## @param processor_list Explicit processor AWK source list.
## @param dot_style_source DOT-style AWK source path.
## @param entrypoint Product entrypoint source path.
## @retval 0 The complete development artifact was written.
main() {
  (($# == 11)) || die "expected 11 arguments; received $#"

  local output=$1
  local project_name=$2
  local version=$3
  local build_date=$4
  local build_commit=$5
  local core_list=$6
  local input_list=$7
  local output_list=$8
  local processor_list=$9
  local dot_style_source=${10}
  local entrypoint=${11}
  local path
  local -a core_sources=()
  local -a input_plugin_sources=()
  local -a output_plugin_sources=()
  local -a processor_awk_sources=()

  [[ -n $project_name && $project_name != *[[:space:]]* ]] \
    || die 'project name must be one non-empty whitespace-free word'
  require_file "$dot_style_source"
  require_file "$entrypoint"

  split_source_list "$core_list" core_sources
  split_source_list "$input_list" input_plugin_sources
  split_source_list "$output_list" output_plugin_sources
  split_source_list "$processor_list" processor_awk_sources

  ((${#core_sources[@]} > 0)) || die 'at least one Bash core source is required'
  ((${#input_plugin_sources[@]} > 0)) \
    || die 'at least one input plugin is required'
  ((${#output_plugin_sources[@]} > 0)) \
    || die 'at least one output plugin is required'
  ((${#processor_awk_sources[@]} > 0)) \
    || die 'at least one processor AWK source is required'

  {
    emit_provenance_header \
      "$project_name" \
      "$version" \
      "$build_date" \
      "$build_commit" \
      "$core_list" \
      "$input_list" \
      "$output_list" \
      "$processor_list" \
      "$dot_style_source" \
      "$entrypoint"

    for path in "${core_sources[@]}"; do
      emit_source_file "$path"
    done
    for path in "${input_plugin_sources[@]}"; do
      emit_source_file "$path"
    done
    for path in "${output_plugin_sources[@]}"; do
      emit_source_file "$path"
    done

    emit_awk_writer \
      figurectl_processor_awk_write \
      "$PROCESSOR_AWK_DELIMITER" \
      "${processor_awk_sources[@]}"
    emit_awk_writer \
      figurectl_dot_style_awk_write \
      "$DOT_STYLE_AWK_DELIMITER" \
      "$dot_style_source"

    emit_source_file "$entrypoint"
  } > "$output"
}

main "$@"
