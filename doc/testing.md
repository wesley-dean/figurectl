# Testing

figurectl uses Bats for behavior-oriented tests and exercises every generated
artifact flavor.  The goal is to validate what consumers execute rather than
assume assembly, embedded-AWK generation, comment stripping, minification,
packaging, or other build transformations cannot change behavior.

Tests live under `tests/`.  Prefer a larger number of focused tests over a small
number of broad fixtures.  A failing test should normally identify one primary
contract.

## Test the Contract, Not an Incidental Snapshot

Tests derive from documented behavior, ADR constraints, source contracts, and
explicit security properties.  They are evidence for the intended contract rather
than the source of architectural intent.

Prefer durable invariants over mutable suite snapshots.  For example:

```text
every shipped artifact receives the same behavior contract
```

is a maintained requirement.  The exact number of tests is ordinary transient CI
output unless a count itself somehow becomes a contract.

## Positive and Negative Assertions

Positive assertions prove that expected behavior occurs.  Security, output
separation, destructive-operation, and fail-closed contracts often require
negative assertions as well.

When the contract says something must not happen, test that absence explicitly.
figurectl examples include:

- unsafe figure identifiers do not create escaped output paths;
- diagnostics and compatibility warnings do not contaminate stdout data;
- non-selected paired figure representations do not leak into output;
- a built artifact does not load implementation files from the maintained source
  tree at runtime;
- a network-free build does not acquire dependencies; and
- stale `.256` checksum companions do not survive a successful build.

Observing the intended replacement, error message, or success value is not enough
if forbidden behavior could still occur through another observable path.

Threat-model findings should drive tests for important mitigations and residual
boundaries where executable evidence is practical.  See `doc/threat-model.md` and
`doc/threat-modeling.md`.

## Public Behavior Contract

`tests/figurectl.bats` runs against each generated artifact through the
`FIGURECTL_ARTIFACT` environment variable.  Coverage includes:

- help and invalid output-format handling;
- source/output mapping;
- metadata parsing and attribute-order tolerance;
- safe and unsafe identifiers;
- paired text/DOT identifiers;
- duplicate same-format identifiers;
- backtick/tilde and longer fences;
- payload containing Markdown-sensitive text such as `-->` and backticks;
- ordinary Markdown preservation;
- metadata/fence format mismatch;
- independent select/render/replace composition;
- text and DOT materialization;
- SVG and PNG rendering;
- caller-owned DOT styling;
- captions and alternative text;
- fallback identifier/alt warnings;
- stdin and named-file input;
- stdout/stderr separation; and
- link-prefix behavior.

Tests should be added when a documented public contract is added or a defect shows
that an existing contract lacks executable evidence.

## Artifact Matrix

`make test` runs the same suite against:

```text
dist/figurectl.dev.bash
dist/figurectl.bash
dist/figurectl.min.bash
```

`make test-report` repeats the matrix and writes one JUnit XML file per artifact
flavor under `test-results/` for CI reporting.

`tests/artifacts.bats` validates representation-specific properties that are not
ordinary public CLI behavior, including:

- executable artifact state;
- `.sha256` checksum companions;
- absence of stale `.256` companions;
- Bash syntax validity;
- generated provenance assignments; and
- retained embedded-AWK documentation only in the development flavor.

Generated artifacts are products.  A change that affects assembly, comment
stripping, minification, embedded dependencies, provenance, or checksums must be
validated against exact artifact bytes and runtime behavior rather than only
against maintained source.

## Embedded AWK Transformation Evidence

The development artifact contains the maintained AWK modules as literal data
inside quoted heredocs.  The ordinary artifact removes full-line comments from the
complete Bash file, including AWK documentation/comment lines inside those
heredocs.  The minified artifact is then derived from the ordinary artifact.

The project therefore treats these transformations as semantic source-to-source
operations that require evidence.  The complete figurectl behavior suite runs
after each representation is produced.  Tests involving regexes, `$`, backticks,
backslashes, Markdown fences, and shell-looking payload text are valuable because
they exercise the language-within-a-language boundary rather than only happy-path
prose.

If maintained AWK ever requires a literal full-line value beginning with `#` as
executable data inside the embedded representation, the comment-stripping
assumption must be revisited before merge.  It must not be dismissed as a test
implementation detail.

## Build-Time Plugin Evidence

Input/output plugin source is discovered by Make before artifact assembly.  Tests
must prove the resulting artifact contains the expected v1.0 capabilities and that
runtime does not depend on the discovered source paths.

CI records discovered plugin paths in development-artifact provenance and verifies
representative paths are present.  Duplicate or malformed registrations fail
conservatively during artifact initialization.

A runtime test copies generated artifacts to an isolated temporary location,
removes `src/`, `lib/`, `scripts/`, and `vendor/`, then performs real text figure
processing.  Passing only `--help` would be insufficient evidence because help
could succeed while runtime parsing still depended on external AWK files.

## Build and Compatibility Evidence

CI plants legacy `.256` companions before a rebuild and verifies that a successful
`make build` removes them while preserving deterministic executable bytes and
valid `.sha256` companions.

Syntax validation and ShellCheck are part of `make check`, not substitutes for
behavior tests.  `make check` also loads the ordered portable-AWK processor and
DOT-style transformer with representative configuration so syntax/assembly defects
surface before artifact testing.

The minimum supported Bash version is a runtime contract.  CI runs
`tests/compat-bash43.bash` against every generated flavor under Bash 4.3 and
performs representative text processing rather than syntax validation alone.

## Conditional Graphviz Tests

Graphviz `dot` is a conditional runtime dependency for SVG/PNG output.  Tests that
exercise graphical output may skip only when Graphviz is genuinely absent from the
test environment.  CI installs Graphviz, so the normal repository workflow is
expected to execute SVG, PNG, and DOT-style coverage rather than skip it.

Graphviz output bytes are not expected to be pixel/byte identical across Graphviz
versions, fonts, or platforms.  Tests should validate required assets and Markdown
references without turning incidental renderer bytes into a portable contract.
