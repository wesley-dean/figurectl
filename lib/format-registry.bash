# shellcheck shell=bash
## @file lib/format-registry.bash
## @brief Registers built-in source and output format capabilities.
## @details
## The build places this explicitly ordered core module before every discovered
## input/output plugin.  Plugin files then register trusted built-in capabilities
## into these arrays while the already-assembled artifact initializes.
##
## Registration is runtime initialization of code already selected during build;
## it is not runtime plugin discovery.  No function in this module scans a
## directory, sources a pathname, consults a plugin search path, or loads code
## supplied after the artifact was built.  ADR-018 and
## `doc/built-in-format-plugins.md` govern that boundary.
##
## Logical names and extensions use a deliberately narrow token grammar so the
## registry can serialize source capabilities for portable AWK without introducing
## another escaping language.  The public figure identifier grammar is separate.

declare -a FIGURECTL_INPUT_FORMATS=()
declare -A FIGURECTL_INPUT_EXTENSIONS=()
declare -a FIGURECTL_OUTPUT_FORMATS=()
declare -A FIGURECTL_OUTPUT_SOURCES=()
declare -A FIGURECTL_OUTPUT_KINDS=()
declare -A FIGURECTL_OUTPUT_EXTENSIONS=()
declare -A FIGURECTL_OUTPUT_RENDERERS=()
declare -A FIGURECTL_OUTPUT_FENCE_INFO=()

## @fn figurectl_registry_token_valid()
## @brief Validates one registry name or extension token.
## @details
## Registry tokens are maintained project metadata rather than user-controlled
## pathnames.  Restricting them to alphanumerics plus `.`, `_`, and `-` keeps the
## semicolon/equals serialization passed to AWK unambiguous.
##
## @param token Token to validate.
## @retval 0 The token matches the registry grammar.
## @retval 1 The token is empty or contains unsupported characters.
figurectl_registry_token_valid() {
  local token=${1:-}
  [[ $token =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

## @fn figurectl_registry_function_valid()
## @brief Validates an optional Bash renderer-function name.
## @details
## Empty renderer names are valid for outputs requiring no renderer.  Non-empty
## values must be ordinary Bash function identifiers so later indirect invocation
## cannot reinterpret punctuation as shell syntax.
##
## @param function_name Function name to validate, or the empty string.
## @retval 0 The value is empty or a valid Bash function identifier.
## @retval 1 The value is not a supported function identifier.
figurectl_registry_function_valid() {
  local function_name=${1:-}
  [[ -z $function_name || $function_name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

## @fn figurectl_registry_fail()
## @brief Reports a malformed maintained registration.
## @details
## Registration failures indicate a defect in the assembled artifact rather than
## invalid end-user CLI input.  The generated artifact runs with `set -e`, so a
## nonzero top-level registration call terminates initialization conservatively.
##
## @param message Diagnostic text without the `figurectl:` prefix.
## @par Standard Error
## Writes one prefixed internal-registration diagnostic.
## @retval 70 The maintained registry contract was violated.
figurectl_registry_fail() {
  printf 'figurectl: registry: %s\n' "$1" >&2
  return 70
}

## @fn figurectl_input_register()
## @brief Registers one authored source representation.
## @details
## Input plugins call this function exactly once at top level.  Duplicate names
## are rejected so behavior cannot depend on whichever discovered peer happened
## to register last.
##
## @param name Logical authored source name.
## @param extension Materialized source-file extension without a leading dot.
## @retval 0 The input capability was registered.
## @retval 70 The registration was malformed or duplicated.
figurectl_input_register() {
  local name=${1:-}
  local extension=${2:-}

  figurectl_registry_token_valid "$name" \
    || figurectl_registry_fail "invalid input format name: ${name}" \
    || return
  figurectl_registry_token_valid "$extension" \
    || figurectl_registry_fail "invalid extension for input ${name}: ${extension}" \
    || return

  if [[ -n ${FIGURECTL_INPUT_EXTENSIONS[$name]:-} ]]; then
    figurectl_registry_fail "input format already registered: ${name}"
    return
  fi

  FIGURECTL_INPUT_FORMATS+=("$name")
  FIGURECTL_INPUT_EXTENSIONS["$name"]=$extension
}

## @fn figurectl_output_register()
## @brief Registers one requested publication format.
## @details
## Output plugins identify the authored source they consume, replacement shape,
## generated extension, optional renderer function, and optional fenced-block
## information string.  The required source must already be registered, which is
## why the build assembles input plugins before output plugins.
##
## `kind` is currently `fence` or `image`.  Fence outputs require a non-empty
## information string and no renderer.  Image outputs require a renderer and do
## not use a fenced information string.
##
## @param name Logical requested output name.
## @param source Registered authored source required by this output.
## @param kind Replacement kind: `fence` or `image`.
## @param extension Generated/public extension without a leading dot.
## @param renderer Bash function that performs rendering, or empty for none.
## @param fence_info Fenced-block information string, or empty for image output.
## @retval 0 The output capability was registered.
## @retval 70 The registration was malformed, duplicated, or referenced an
## unregistered source.
figurectl_output_register() {
  local name=${1:-}
  local source=${2:-}
  local kind=${3:-}
  local extension=${4:-}
  local renderer=${5:-}
  local fence_info=${6:-}

  figurectl_registry_token_valid "$name" \
    || figurectl_registry_fail "invalid output format name: ${name}" \
    || return
  figurectl_registry_token_valid "$source" \
    || figurectl_registry_fail "invalid source name for output ${name}: ${source}" \
    || return
  figurectl_registry_token_valid "$extension" \
    || figurectl_registry_fail "invalid extension for output ${name}: ${extension}" \
    || return
  figurectl_registry_function_valid "$renderer" \
    || figurectl_registry_fail "invalid renderer for output ${name}: ${renderer}" \
    || return

  if [[ -z ${FIGURECTL_INPUT_EXTENSIONS[$source]:-} ]]; then
    figurectl_registry_fail \
      "output ${name} references unregistered source format: ${source}"
    return
  fi
  if [[ -n ${FIGURECTL_OUTPUT_SOURCES[$name]:-} ]]; then
    figurectl_registry_fail "output format already registered: ${name}"
    return
  fi

  case "$kind" in
    fence)
      [[ -z $renderer ]] \
        || figurectl_registry_fail \
          "fence output ${name} must not declare a renderer" \
        || return
      figurectl_registry_token_valid "$fence_info" \
        || figurectl_registry_fail \
          "fence output ${name} requires a valid information string" \
        || return
      ;;
    image)
      [[ -n $renderer ]] \
        || figurectl_registry_fail \
          "image output ${name} requires a renderer" \
        || return
      [[ -z $fence_info ]] \
        || figurectl_registry_fail \
          "image output ${name} must not declare fence information" \
        || return
      ;;
    *)
      figurectl_registry_fail "invalid replacement kind for output ${name}: ${kind}"
      return
      ;;
  esac

  FIGURECTL_OUTPUT_FORMATS+=("$name")
  FIGURECTL_OUTPUT_SOURCES["$name"]=$source
  FIGURECTL_OUTPUT_KINDS["$name"]=$kind
  FIGURECTL_OUTPUT_EXTENSIONS["$name"]=$extension
  FIGURECTL_OUTPUT_RENDERERS["$name"]=$renderer
  FIGURECTL_OUTPUT_FENCE_INFO["$name"]=$fence_info
}

## @fn figurectl_output_supported()
## @brief Tests whether the artifact contains a requested output implementation.
## @param name Logical requested output name.
## @retval 0 The output is registered in this artifact.
## @retval 1 The output is not registered.
figurectl_output_supported() {
  local name=${1:-}
  [[ -n $name && -n ${FIGURECTL_OUTPUT_SOURCES[$name]:-} ]]
}

## @fn figurectl_output_source()
## @brief Returns the authored source required by a requested output.
## @param name Logical requested output name.
## @par Standard Output
## Writes the registered authored source when found.
## @retval 0 The output exists and its source was written.
## @retval 1 The output is not registered.
figurectl_output_source() {
  local name=${1:-}
  figurectl_output_supported "$name" || return 1
  printf '%s\n' "${FIGURECTL_OUTPUT_SOURCES[$name]}"
}

## @fn figurectl_output_kind()
## @brief Returns the replacement kind for a requested output.
## @param name Logical requested output name.
## @par Standard Output
## Writes `fence` or `image`.
## @retval 0 The output exists and its kind was written.
## @retval 1 The output is not registered.
figurectl_output_kind() {
  local name=${1:-}
  figurectl_output_supported "$name" || return 1
  printf '%s\n' "${FIGURECTL_OUTPUT_KINDS[$name]}"
}

## @fn figurectl_output_extension()
## @brief Returns the public/generated extension for a requested output.
## @param name Logical requested output name.
## @par Standard Output
## Writes the registered extension without a leading dot.
## @retval 0 The output exists and its extension was written.
## @retval 1 The output is not registered.
figurectl_output_extension() {
  local name=${1:-}
  figurectl_output_supported "$name" || return 1
  printf '%s\n' "${FIGURECTL_OUTPUT_EXTENSIONS[$name]}"
}

## @fn figurectl_output_renderer()
## @brief Returns the renderer function registered for a requested output.
## @param name Logical requested output name.
## @par Standard Output
## Writes the renderer function name or an empty line when rendering is not
## required.
## @retval 0 The output exists and its renderer field was written.
## @retval 1 The output is not registered.
figurectl_output_renderer() {
  local name=${1:-}
  figurectl_output_supported "$name" || return 1
  printf '%s\n' "${FIGURECTL_OUTPUT_RENDERERS[$name]}"
}

## @fn figurectl_output_fence_info()
## @brief Returns the fenced information string for a requested output.
## @param name Logical requested output name.
## @par Standard Output
## Writes the information string or an empty line for non-fence output.
## @retval 0 The output exists and its field was written.
## @retval 1 The output is not registered.
figurectl_output_fence_info() {
  local name=${1:-}
  figurectl_output_supported "$name" || return 1
  printf '%s\n' "${FIGURECTL_OUTPUT_FENCE_INFO[$name]}"
}

## @fn figurectl_input_spec()
## @brief Serializes registered authored-source capabilities for portable AWK.
## @details
## The result uses `name=extension` entries separated by semicolons.  Registry
## token validation guarantees that neither delimiter can appear in a name or
## extension, so the AWK side can parse the string without an escape convention.
##
## @par Standard Output
## Writes one semicolon-delimited source capability specification.
## @retval 0 The specification was written.
figurectl_input_spec() {
  local name
  local separator=''

  for name in "${FIGURECTL_INPUT_FORMATS[@]}"; do
    printf '%s%s=%s' \
      "$separator" \
      "$name" \
      "${FIGURECTL_INPUT_EXTENSIONS[$name]}"
    separator=';'
  done
  printf '\n'
}
