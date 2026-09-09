#!/usr/bin/env bash
set -euo pipefail

: "${FIGURECTL_ARTIFACT:?FIGURECTL_ARTIFACT must identify the artifact under test}"

bash -n "${FIGURECTL_ARTIFACT}"
"${FIGURECTL_ARTIFACT}" --help >/dev/null

workdir=$(mktemp -d "${TMPDIR:-/tmp}/figurectl-bash43.XXXXXX")
trap 'rm -rf "$workdir"' EXIT

cat >"${workdir}/input.md" <<'EOF'
Before

<!-- figure id="compat" format="text" alt="Compatibility" -->
```text
Bash 4.3
```
EOF

"${FIGURECTL_ARTIFACT}" process \
  --format text \
  --figures-dir "${workdir}/figures" \
  --output "${workdir}/output.md" \
  "${workdir}/input.md"

grep -Fq -- '```text' "${workdir}/output.md"
grep -Fq -- 'Bash 4.3' "${workdir}/output.md"
test -s "${workdir}/figures/compat.txt"
