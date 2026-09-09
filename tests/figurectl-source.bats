#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  FIGURECTL_SOURCE="${REPO_ROOT}/src/orchestrator.bash"
  TEST_ROOT="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/figurectl-source.XXXXXX")"
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

@test "select keeps the requested source representation and ordinary Markdown" {
  write_paired_figure

  run bash "${FIGURECTL_SOURCE}" select --format text "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'adrctl.bash generate graph > doc/adr/decisions.dot'* ]]
  [[ "${output}" == *'+--> branch'* ]]
  [[ "${output}" == *'format="text"'* ]]
  [[ "${output}" != *'digraph {'* ]]
  [[ "${output}" != *'format = "dot"'* ]]
}

@test "process text materializes text and replaces figure directives" {
  write_paired_figure

  run bash "${FIGURECTL_SOURCE}" process \
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

  bash "${FIGURECTL_SOURCE}" select --format dot "${INPUT_FILE}" >"${selected}"
  run bash "${FIGURECTL_SOURCE}" render \
    --format dot \
    --figures-dir "${FIGURES_DIR}" \
    "${selected}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure01.dot" ]

  bash "${FIGURECTL_SOURCE}" replace \
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

  run bash "${FIGURECTL_SOURCE}" process \
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

  run bash "${FIGURECTL_SOURCE}" select --format text "${INPUT_FILE}"

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'duplicate text figure id: duplicate'* ]]
}

@test "unsafe figure identifiers are rejected before filesystem use" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure id="../escape" format="text" alt="Unsafe" -->
```text
unsafe
```
EOF

  run bash "${FIGURECTL_SOURCE}" process \
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

  run bash "${FIGURECTL_SOURCE}" select --format text "${INPUT_FILE}"

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

  run bash "${FIGURECTL_SOURCE}" process \
    --format text \
    --figures-dir "${FIGURES_DIR}" \
    "${INPUT_FILE}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'payload with ``` inside'* ]]
  [[ "${output}" == *'````text'* ]]
}

@test "missing id and alt retain compatibility fallback behavior" {
  cat >"${INPUT_FILE}" <<'EOF'
<!-- figure format="text" -->
```text
fallback
```
EOF

  local stderr_file="${TEST_ROOT}/stderr.txt"
  run bash -c 'bash "$1" process --format text --figures-dir "$2" "$3" 2>"$4"' \
    _ "${FIGURECTL_SOURCE}" "${FIGURES_DIR}" "${INPUT_FILE}" "${stderr_file}"

  [ "${status}" -eq 0 ]
  [ -s "${FIGURES_DIR}/figure-001.txt" ]
  grep -Fq -- 'warning: missing id; using figure-001' "${stderr_file}"
  grep -Fq -- \
    'warning: figure figure-001 is missing alt text' \
    "${stderr_file}"
  [[ "${output}" == *'fallback'* ]]
}

@test "standard input is used when no input path is supplied" {
  cat >"${INPUT_FILE}" <<'EOF'
Before

<!-- figure id="stdin" format="text" alt="STDIN" -->
```text
from stdin
```
EOF

  run bash -c 'cat "$1" | bash "$2" process --format text --figures-dir "$3"' \
    _ "${INPUT_FILE}" "${FIGURECTL_SOURCE}" "${FIGURES_DIR}"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'Before'* ]]
  [[ "${output}" == *'from stdin'* ]]
  [ -s "${FIGURES_DIR}/stdin.txt" ]
}

@test "png output uses dot source and caller-selected link prefix" {
  command -v dot >/dev/null 2>&1 || skip "Graphviz dot is not installed"
  write_paired_figure
  local png_dir="${TEST_ROOT}/png"
  local link_prefix="assets/figures"
  mkdir -p "${png_dir}"

  run bash "${FIGURECTL_SOURCE}" process \
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
