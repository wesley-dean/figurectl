# Maintained Source Extraction

This document records the narrow implementation boundary used while extracting
`figurectl` from `wesley-dean/writing` into the standalone repository.

The public behavior remains governed by [`specification.md`](specification.md) and
ADR-017.  The build-time input/output plugin architecture is governed by ADR-018.
This document preserves the phase-2 compatibility milestone and the deliberately
retained implementation behaviors that remain useful context after artifact
assembly replaced the temporary source-runner boundary.

## Compatibility Baseline

The extraction is based on:

```text
repository: wesley-dean/writing
path:       scripts/figurectl.bash
commit:     02e67755dd992e658084e9cbc279480672bcbf00
blob:       bbabf7313c757e0e12866764f12fecd5e9285c3e
```

Behavior-preserving extraction means that implementation cleanup, parser
improvements, output normalization, and broader format semantics do not enter the
migration merely because modular source makes them convenient.

## Phase-2 Maintained Source Shape

The original extracted processor source was:

```text
src/orchestrator.bash
lib/awk/common.awk
lib/awk/metadata.awk
lib/awk/fences.awk
lib/awk/actions.awk
lib/awk/main.awk
lib/awk/dot-style.awk
```

During phase 2, `src/orchestrator.bash` was a development-source execution path.
It invoked processor modules directly through repeated `awk -f` arguments so
compatibility could be tested before the build and distribution architecture was
changed.

That temporary runtime source-tree dependency is no longer the consumer contract.
Phase 3 retains the modular AWK files as maintained source, adds capability-driven
format data, and embeds the ordered AWK program into standalone generated Bash
artifacts during `make build`.

## Phase-3 Artifact Boundary

The product implementation now separates responsibilities as follows:

```text
src/orchestrator.bash
lib/format-registry.bash
lib/renderers/graphviz.bash
lib/plugins/input/*.bash
lib/plugins/output/*.bash
lib/awk/common.awk
lib/awk/capabilities.awk
lib/awk/metadata.awk
lib/awk/fences.awk
lib/awk/actions.awk
lib/awk/main.awk
lib/awk/dot-style.awk
scripts/build-artifact.bash
```

Make discovers additive input/output plugin source at build time, while core Bash
and AWK ordering remains explicit.  The generated artifact contains the selected
format registrations plus literal embedded AWK source and therefore no longer
needs the maintained repository tree at runtime.

The build/artifact architecture is described in
[`built-in-format-plugins.md`](built-in-format-plugins.md).  Security implications
of source assembly, heredoc embedding, temporary AWK materialization, format
registration, path validation, and Graphviz invocation are recorded in
[`threat-model.md`](threat-model.md).

## Deliberately Preserved Behaviors

The migration preserves behaviors that may deserve later review, including:

- the physical select, render, and replace passes used by `process`;
- `/dev/stdin` as the AWK pathname for standard input;
- the existing metadata grammar and quoted-value behavior;
- sequential fallback identifiers and generic alternative-text warnings;
- existing payload newline accumulation;
- DOT style insertion after the first textual `{` rather than syntax-aware DOT
  parsing;
- shared option parsing that accepts options not used by every subcommand; and
- current exit-status distinctions between usage/parser failures and Bash-level
  runtime failures.

Preservation is not a claim that each behavior is ideal.  It keeps extraction,
build architecture, and later parser redesign independently reviewable.

## Test Boundary Evolution

Phase 2 used `tests/figurectl-source.bats` to exercise the maintained-source runner
directly while the inherited template artifact matrix remained intact.

Phase 3 retires that transitional distinction.  `tests/figurectl.bats` is now the
public behavior contract and runs unchanged against the development, ordinary,
and minified generated artifacts.  Artifact-specific tests validate checksums,
syntax, provenance, and representation differences.  CI additionally copies the
generated files away from the repository source/dependency trees and performs real
text processing to prove the standalone runtime boundary.

The unsafe-identifier regression originally exposed while phase 2 was under review
is retained in the artifact behavior contract.  It is treated as a required
security/property check, not discarded because the transitional suite exposed an
unexpected result.

## Historical Value

This file is intentionally retained after phase 3 because it records which
behaviors came from the writing-repository baseline and which implementation
choices were deliberately left unchanged during extraction.  Future cleanup should
compare proposed behavior changes against the public specification and governing
ADRs rather than treating the phase-2 source shape itself as permanent
architecture.
