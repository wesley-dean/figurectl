# AGENTS.md

This file is the concise operational map for contributors and AI-assisted tools
working on figurectl.  It is intentionally smaller than the ADR corpus.

## Start Here

Before consequential work:

1. Read `README.md` for the project overview and current migration status.
2. Read `doc/specification.md` for the intended public behavior contract.
3. Read `doc/engineering-philosophy.md` for reusable engineering posture.
4. Read `doc/decisions.md` for the concise architectural map.
5. Read the ADR index in `doc/adr/README.md` and the ADRs governing the area being
   changed.
6. Read `doc/threat-modeling.md` when work changes authority, untrusted-input
   handling, filesystem output, subprocess behavior, dependencies, build
   transformations, dynamic loading, or other security-relevant boundaries.
7. Read `doc/documentation-standard.md` before editing maintained Bash comments.
8. Read `doc/awk-documentation-standard.md` before editing maintained AWK source.
9. Read `doc/testing.md` before changing tests or generated artifacts.
10. Read `doc/release-verification.md` before changing release behavior.

When implementation, tests, specification, and an Accepted ADR conflict, surface
the conflict.  Do not silently treat current code as the architectural source of
truth.

## Current Migration State

The repository is being adapted from template-bash into the standalone figurectl
product.

The governance/specification work defines the intended compatibility target before
runtime migration.  Until the implementation extraction lands, inherited template
runtime behavior may still exist in `src/` and `lib/`; do not treat that starter
behavior as figurectl's public contract merely because it is executable.

The compatibility baseline is the figure-processing behavior originally maintained
as `scripts/figurectl.bash` in `wesley-dean/writing`.

## Public Contract

The initial public commands are:

```text
select
render
replace
process
```

The initial authored source formats are `text` and `dot`.  Requested outputs are
`text`, `dot`, `svg`, and `png`, with SVG/PNG derived from DOT.

The source form is an HTML metadata comment immediately followed by a native
fenced code block.  Metadata stays outside the payload.  Ordinary Markdown outside
recognized figure declarations passes through unchanged.

See `doc/specification.md` and ADR-017.

## Source and Plugin Architecture

The intended maintained implementation is responsibility-focused Bash plus portable
AWK.

Core source ordering is explicit.  Input/output modules that are genuinely
additive may be discovered deterministically during build.

Plugin discovery is **build-time only**.  Generated artifacts contain every
implementation they support.

Do not add runtime plugin directory scanning, dynamic sourcing, hot loading,
third-party plugin installation paths, or arbitrary plugin search paths.  Any
external runtime plugin mechanism requires a new ADR because it changes trust,
distribution, and compatibility boundaries.

See ADR-014 and ADR-018.

## Bash and AWK Portability

The Bash compatibility floor is 4.3 unless a later Accepted ADR raises it.
Do not use post-4.3 Bash features accidentally.

Maintained AWK is portable AWK unless governing documentation explicitly records
an implementation-specific dependency.  Do not introduce gawk-only, mawk-only,
or BusyBox-specific behavior without surfacing the compatibility change.

Graphviz `dot` is a conditional runtime dependency for SVG/PNG rendering only.

## Documentation Standards

Maintained Bash follows `doc/documentation-standard.md` and ADR-007.

Maintained AWK follows `doc/awk-documentation-standard.md` and ADR-019.  In
particular:

- use `##` Doxygen blocks;
- document files with `@file`, `@brief`, and substantive `@details`;
- document AWK functions with `@fn`, `@param`, `@local`, stream behavior, and
  `@returns` according to the standard;
- use `@var` for significant project-owned global state where useful;
- use stable `@rule` identities for important `BEGIN`, `END`, and pattern/action
  rules;
- document record context, global-state lifecycle, regex interpretation,
  `getline`, file access, subprocess behavior, and portability assumptions when
  relevant.

The `awk-doxygen` filter is being developed separately.  Lack of generated AWK
reference output does not relax the maintained-source documentation standard.

## Build and Dependency Boundaries

GNU Make is the canonical development/CI orchestration surface.

- `make deps` may access the network and repair repository dependency state.
- `make deps-check` verifies prepared dependency state offline.
- `make build` consumes maintained source and prepared dependencies without
  synchronizing dependencies.
- `make all` runs `deps` then `build`.
- `make docs`, `make test`, and `make test-report` consume prepared state and must
  not silently synchronize dependencies.

bashdeps manages repository dependencies, not system packages.  Build/runtime
system commands such as Make, Bash, AWK, Graphviz, Bats, Doxygen, ShellCheck, and
shfmt remain outside bashdeps package-management scope.

## Release Artifacts

The intended release files are:

```text
dist/figurectl.dev.bash
dist/figurectl.dev.bash.sha256
dist/figurectl.bash
dist/figurectl.bash.sha256
dist/figurectl.min.bash
dist/figurectl.min.bash.sha256
```

All executable flavors represent the same public program and must receive the
same observable behavior suite.

The ordinary `figurectl.bash` artifact is the conventional/default consumer
artifact.  The development artifact retains documentation.  The minified artifact
is derived from the ordinary artifact using prepared Bash-Minifier state.

Because the Bash artifact will contain embedded AWK source, tests must prove that
assembly, comment stripping, and minification preserve behavior rather than
assuming those transformations are harmless.

## Testing

Follow documentation-driven, test-second development under ADR-008.

For consequential behavior:

1. identify or create governing ADR/specification text;
2. write or update source documentation contracts;
3. add focused behavior tests;
4. implement the smallest coherent change;
5. validate all relevant artifact flavors; and
6. compare the result back against the governing constraints.

Tests should cover observable behavior rather than incidental source layout.
Negative assertions are required where the contract says something must not
occur, such as unsafe pathname use, unexpected diagnostics on stdout, runtime
plugin discovery, or leakage of non-selected figure representations.

## Scope Discipline

Prefer the smallest coherent change that satisfies governing decisions.  Do not
mix unrelated cleanup into extraction work.

The initial implementation migration should preserve behavior before improving the
parser or changing public semantics.  Identified defects or cleanup opportunities
should be handled as separate reviewable changes unless they block compatibility.

## Repository Locations

- `src/`: product-facing Bash orchestration/entrypoint source.
- `lib/`: maintained implementation modules.
- `tests/`: Bats behavior tests and fixtures.
- `doc/specification.md`: intended public figurectl contract.
- `doc/decisions.md`: concise Accepted-decision map.
- `doc/adr/`: full architectural decisions.
- `doc/documentation-standard.md`: maintained Bash documentation standard.
- `doc/awk-documentation-standard.md`: maintained AWK documentation standard.
- `doc/threat-modeling.md`: security-analysis guidance.
- `doc/reference/`: generated reference documentation; do not commit.
- `vendor/`: generated dependency state; do not commit.
- `dist/`: generated release artifacts; do not edit directly.
- `test-results/`: generated JUnit reports.
