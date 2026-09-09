#!/usr/bin/env bats

setup() {
  : "${FIGURECTL_ARTIFACT:?FIGURECTL_ARTIFACT must identify the artifact under test}"
  TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/figurectl.XXXXXX")"
  FIGURES_DIR="${TEST_ROOT}/figures"
  INPUT_FILE="${TEST_ROOT}/input.md"
  OUTPUT_FILE="${TEST_ROOT}/output.md"
  mkdir -p "${FIGURES_DIR}"
}

teardown() {
  rm -rf "${TEST_ROOT}"
}

write_paired_figure() {
  cat >"${INPUT_FILE}" <<'EOF'
# Figure test

Ordinary fenced content that happens to mention DOT must remain ordinary
Markdown:

```shell
adrctl.bash generate graph > doc/adr/decisions.dot
```

<!-- figure id="figure01" format="text"
     alt="Build flow" caption="Figure 1: Build flow" -->
```text
source
  |
  +--> branch
  |
  v
build
```

<!-- figure format = "dot"
     caption = "Figure 1: Build flow"
     alt = "Build flow"
     id = "figure01" -->
```dot
digraph {
  source [label="Source"];
  build [label="Build"];
  source -> build;
}
```
EOF
}

@test "help describes the figurectl command surface" {
  run "${FIGURECTL_ARTIFACT}" --help

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'figurectl.bash select'* ]]
  [[ "${output}" == *'figurectl.bash render'* ]]
  [[ "${output}" == *'figurectl.bash replace'* ]]
  [[ "${output}" == *'figurectl.bash process'* ]]
  [[ "${output}" == *'Formats: text, dot, svg, png'* ]]
}

@test "unsupported requested formats are rejected as invalid usage" {
  run "${FIGURECTL_ARTIFACT}" select --format jpeg "${INPUT_FILE}"

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'unsupported format: jpeg'* ]]
}

@test "select keeps the requested source representation and ordinary Markdown" {
  write_paired_figure

  run "${FIGURECTL_ARTIFACT}" select --format text "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'adrctl.bash generate graph > doc/adr/decisions.dot'* ]]
  [[ "${output}" == *'+--> branch'* ]]
  [[ "${output}" == *'format="text"'* ]]
  [[ "${output}" != *'digraph {'* ]]
  [[ "${output}" != *'format = "dot"'* ]]
}

@test "process text materializes text and replaces figure directives" {
  write_paired_figure

  run "${FIGURECTL_ARTIFACT}" process \
    --format text \
    --figures-dir "${FIGURES_DIR}" \
    --output "${OUTPUT_FILE}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure01.txt" ]
  grep -Fq -- '```text' "${OUTPUT_FILE}"
  grep -Fq -- '+--> branch' "${OUTPUT_FILE}"
  grep -Fq -- '*Figure 1: Build flow*' "${OUTPUT_FILE}"
  grep -Fq -- 'adrctl.bash generate graph > doc/adr/decisions.dot' "${OUTPUT_FILE}"
  ! grep -Fq -- '<!-- figure' "${OUTPUT_FILE}"
  ! grep -Fq -- 'digraph {' "${OUTPUT_FILE}"
}

@test "select render and replace compose as separate public phases" {
  write_paired_figure
  local selected="${TEST_ROOT}/selected.md"
  local replaced="${TEST_ROOT}/replaced.md"

  "${FIGURECTL_ARTIFACT}" select --format dot "${INPUT_FILE}" >"${selected}"

  run "${FIGURECTL_ARTIFACT}" render \
    --format dot \
    --figures-dir "${FIGURES_DIR}" \
    "${selected}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure01.dot" ]

  "${FIGURECTL_ARTIFACT}" replace \
    --format dot \
    --figures-dir "${FIGURES_DIR}" \
    "${selected}" >"${replaced}"

  grep -Fq -- '```dot' "${replaced}"
  grep -Fq -- 'source -> build;' "${replaced}"
  grep -Fq -- '*Figure 1: Build flow*' "${replaced}"
  ! grep -Fq -- '<!-- figure' "${replaced}"
}

@test "paired text and dot representations may share one identifier" {
  write_paired_figure

  run "${FIGURECTL_ARTIFACT}" process \
    --format text \
    --figures-dir "${FIGURES_DIR}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'+--> branch'* ]]
  [[ "${output}" != *'digraph {'* ]]
}

@test "duplicate identifiers within one source format are rejected" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure id="duplicate" format="text" alt="First" -->
```text
first
```

<!-- figure id="duplicate" format="text" alt="Second" -->
```text
second
```
EOF

  run "${FIGURECTL_ARTIFACT}" select --format text "${INPUT_FILE}"

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'duplicate text figure id: duplicate'* ]]
}

@test "unsafe figure identifiers are rejected before escaped output is written" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure id="../escape" format="text" alt="Unsafe" -->
```text
unsafe
```
EOF

  run "${FIGURECTL_ARTIFACT}" process \
    --format text \
    --figures-dir "${FIGURES_DIR}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'unsafe figure id: ../escape'* ]]
  [ ! -e "${TEST_ROOT}/escape.txt" ]
}

@test "metadata and fence source formats must agree" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure id="mismatch" format="text" alt="Mismatch" -->
```dot
not actually text
```
EOF

  run "${FIGURECTL_ARTIFACT}" select --format text "${INPUT_FILE}"

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'declares format text but fence uses dot'* ]]
}

@test "tilde fences and fences longer than three characters are accepted" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure id="tilde" format="text" alt="Tilde fence" -->
~~~~text
payload with ``` inside
~~~~
EOF

  run "${FIGURECTL_ARTIFACT}" process \
    --format text \
    --figures-dir "${FIGURES_DIR}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'payload with ``` inside'* ]]
  [[ "${output}" == *'````text'* ]]
}

@test "missing id and alt retain compatibility fallback behavior on stderr" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure format="text" -->
```text
fallback
```
EOF

  local stdout_file="${TEST_ROOT}/stdout.txt"
  local stderr_file="${TEST_ROOT}/stderr.txt"

  run bash -c '"$1" process --format text --figures-dir "$2" "$3" >"$4" 2>"$5"' \
    _ "${FIGURECTL_ARTIFACT}" "${FIGURES_DIR}" "${INPUT_FILE}" \
    "${stdout_file}" "${stderr_file}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure-001.txt" ]
  grep -Fq -- 'warning: missing id; using figure-001' "${stderr_file}"
  grep -Fq -- \
    'warning: figure figure-001 is missing alt text' \
    "${stderr_file}"
  grep -Fq -- 'fallback' "${stdout_file}"
  ! grep -Fq -- 'warning:' "${stdout_file}"
}

@test "standard input is used when no input path is supplied" {
  cat >"${INPUT_FILE}" <<'EOF'
Before

<!-- figure id="stdin" format="text" alt="STDIN" -->
```text
from stdin
```
EOF

  run bash -c 'cat "$1" | "$2" process --format text --figures-dir "$3"' \
    _ "${INPUT_FILE}" "${FIGURECTL_ARTIFACT}" "${FIGURES_DIR}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'Before'* ]]
  [[ "${output}" == *'from stdin'* ]]
  [ -s "${FIGURES_DIR}/stdin.txt" ]
}

@test "svg output uses dot source and caller-selected link prefix" {
  command -v dot >/dev/null 2>&1 || skip "Graphviz dot is not installed"
  write_paired_figure
  local svg_dir="${TEST_ROOT}/svg"
  local link_prefix="assets/figures"
  mkdir -p "${svg_dir}"

  run "${FIGURECTL_ARTIFACT}" process \
    --format svg \
    --figures-dir "${svg_dir}" \
    --link-prefix "${link_prefix}" \
    --output "${OUTPUT_FILE}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [ -s "${svg_dir}/figure01.dot" ]
  [ -s "${svg_dir}/figure01.svg" ]
  grep -Fq -- '![Build flow](assets/figures/figure01.svg)' "${OUTPUT_FILE}"
  ! grep -Fq -- '+--> branch' "${OUTPUT_FILE}"
  ! grep -Fq -- 'digraph {' "${OUTPUT_FILE}"
}

@test "png output uses dot source and caller-selected link prefix" {
  command -v dot >/dev/null 2>&1 || skip "Graphviz dot is not installed"
  write_paired_figure
  local png_dir="${TEST_ROOT}/png"
  local link_prefix="assets/figures"
  mkdir -p "${png_dir}"

  run "${FIGURECTL_ARTIFACT}" process \
    --format png \
    --figures-dir "${png_dir}" \
    --link-prefix "${link_prefix}" \
    --output "${OUTPUT_FILE}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [ -s "${png_dir}/figure01.dot" ]
  [ -s "${png_dir}/figure01.png" ]
  grep -Fq -- '![Build flow](assets/figures/figure01.png)' "${OUTPUT_FILE}"
  ! grep -Fq -- '+--> branch' "${OUTPUT_FILE}"
  ! grep -Fq -- 'digraph {' "${OUTPUT_FILE}"
}

@test "caller-owned DOT style is applied before Graphviz rendering" {
  command -v dot >/dev/null 2>&1 || skip "Graphviz dot is not installed"
  write_paired_figure
  local style_file="${TEST_ROOT}/style.dot"

  cat >"${style_file}" <<'EOF'
  graph [rankdir=LR];
EOF

  run "${FIGURECTL_ARTIFACT}" process \
    --format svg \
    --figures-dir "${FIGURES_DIR}" \
    --dot-style "${style_file}" \
    --output "${OUTPUT_FILE}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure01.svg" ]
}
