# Maintained Source Extraction

This document records the narrow implementation boundary used while extracting
`figurectl` from `wesley-dean/writing` into the standalone repository.

The public behavior remains governed by [`specification.md`](specification.md) and
ADR-017.  The longer-term build-time input/output plugin architecture remains
governed by ADR-018.  This document describes the temporary maintained-source
shape used to prove compatibility between those two milestones.

## Compatibility Baseline

The extraction is based on:

```text
repository: wesley-dean/writing
path:       scripts/figurectl.bash
commit:     02e67755dd992e658084e9cbc279480672bcbf00
blob:       bbabf7313c757e0e12866764f12fecd5e9285c3e
```

Behavior-preserving extraction means that implementation cleanup, parser
improvements, output normalization, and broader format abstractions do not enter
this phase merely because modular source makes them convenient.

## Maintained Source Shape

The extracted source is:

```text
src/orchestrator.bash
lib/awk/common.awk
lib/awk/metadata.awk
lib/awk/fences.awk
lib/awk/actions.awk
lib/awk/main.awk
lib/awk/dot-style.awk
```

`src/orchestrator.bash` is a development-source execution path.  It invokes the
processor modules with explicit repeated `awk -f` arguments and invokes the DOT
style transformer separately when a graphical render uses `--dot-style`.

The source runner intentionally depends on the maintained repository tree.  That
is not the intended consumer distribution contract.  Phase 3 will assemble the
selected built-in implementations into standalone `figurectl*.bash` artifacts as
required by ADR-018 and the inherited artifact-governance decisions.

## Deliberately Preserved Behaviors

This extraction preserves behaviors that may deserve later review, including:

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

Preservation here is not a claim that each behavior is ideal.  It prevents
migration and redesign from becoming one inseparable review surface.

## Test Boundary

`tests/figurectl-source.bats` exercises the maintained-source runner directly.
The regression cases are adapted from the writing repository's figure-processing
coverage and expanded into focused checks for selection, phase composition,
paired identifiers, duplicate rejection, safe identifiers, fence validation,
fallback metadata, standard input, and graphical output when Graphviz is
available.

The inherited template artifact matrix remains temporarily intact.  Phase 3 must
apply the figurectl behavior contract to the actual development, ordinary, and
minified figurectl artifacts and remove the temporary distinction between source
regression coverage and artifact coverage.
