# AGENTS.md

This file is the concise operational map for contributors and AI-assisted tools
working on figurectl.  It is intentionally smaller than the ADR corpus.

## Start Here

Before consequential work:

1. Read `README.md` for the project overview and migration/release state.
2. Read `doc/specification.md` for the public behavior contract.
3. Read `doc/engineering-philosophy.md` for reusable engineering posture.
4. Read `doc/decisions.md` for the concise architectural map.
5. Read the ADR index in `doc/adr/README.md` and the ADRs governing the area being
   changed.
6. Read `doc/built-in-format-plugins.md` before changing source/output plugin
   registration, discovery, dispatch, or capability serialization.
7. Read `doc/threat-model.md` and `doc/threat-modeling.md` when work changes
   authority, untrusted-input handling, filesystem output, subprocess behavior,
   dependencies, build transformations, plugin boundaries, release permissions,
   or other security-relevant behavior.
8. Read `doc/documentation-standard.md` before editing maintained Bash comments.
9. Read `doc/awk-documentation-standard.md` before editing maintained AWK source.
10. Read `doc/testing.md` before changing tests or generated artifacts.
11. Read `doc/release-verification.md` before changing release behavior.

When implementation, tests, specification, and an Accepted ADR conflict, surface
the conflict.  Do not silently treat current code as the architectural source of
truth.

## Current Migration State

The behavior-preserving extraction from `wesley-dean/writing` exists as maintained
modular Bash/AWK source, and the artifact migration assembles that source into
standalone figurectl development, ordinary, and minified Bash files.

Input/output plugin discovery occurs only during `make build`.  Generated
artifacts contain their format implementations and embedded AWK programs; they do
not require `src/`, `lib/`, `scripts/`, `vendor/`, or plugin directories at
runtime.

The remaining cross-repository migration is adoption by `wesley-dean/writing`
after a suitable figurectl release exists.  Release readiness and writing-repo
adoption are separate review surfaces.

The compatibility baseline remains the figure-processing behavior originally
maintained as `scripts/figurectl.bash` in `wesley-dean/writing`.

## Public Contract

The public commands are:

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

Maintained implementation uses responsibility-focused Bash plus portable AWK.

Bash core source is explicitly ordered.  Input plugins under
`lib/plugins/input/` and output plugins under `lib/plugins/output/` are additive
leaf modules discovered deterministically during build.  They register
capabilities into `lib/format-registry.bash` after they have already been selected
for artifact assembly.

The registry is runtime initialization of built-in code, **not runtime plugin
discovery**.  Generated artifacts do not scan directories, source implementation
files, honor plugin search paths, or load third-party code.

The portable AWK parser remains explicitly ordered core source under `lib/awk/`.
Build assembly concatenates the ordered AWK modules into literal quoted heredocs
inside generated Bash artifacts.  Runtime writes the trusted embedded AWK to a
`mktemp` pathname and invokes `awk -f`; it does not load maintained AWK files.

Do not add runtime plugin directory scanning, dynamic sourcing, hot loading,
third-party plugin installation paths, or arbitrary plugin search paths.  Any
external runtime plugin mechanism requires a new ADR because it changes trust,
distribution, and compatibility boundaries.

See ADR-014, ADR-018, and `doc/built-in-format-plugins.md`.

## Build-Time Format Contract

Input plugins register:

```text
logical source name
materialized source extension
```

Output plugins register:

```text
logical output name
required authored source
replacement kind
output extension
optional renderer function
optional fenced-block information string
```

Current replacement kinds are `fence` and `image`.  SVG and PNG register the
shared Graphviz renderer.  Core orchestration must query these capabilities rather
than reintroducing distributed `case` statements for every supported format.

Peer plugin order must not carry hidden semantic dependencies.  If order becomes
architecturally meaningful, move that dependency into explicit core ordering or
record a governing decision.

## Bash and AWK Portability

The Bash compatibility floor is 4.3 unless a later Accepted ADR raises it.  Do not
use post-4.3 Bash features accidentally.

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

Generated AWK reference documentation requires a suitable pinned `awk-doxygen`
release.  Until that dependency is deliberately adopted, lack of generated AWK
reference output does not relax the maintained-source documentation standard.

## Build and Dependency Boundaries

GNU Make is the canonical development/CI orchestration surface.

- `make deps` may access the network and repair repository dependency state.
- `make deps-check` verifies prepared dependency state offline.
- `make build` consumes maintained source and prepared dependencies without
  synchronizing dependencies.
- `make all` runs `deps` then `build`.
- `make check` validates maintained Bash and portable-AWK source.
- `make test` and `make test-report` exercise the exact generated artifacts.
- `make docs` consumes prepared documentation dependencies and must not silently
  synchronize them.

bashdeps manages repository dependencies, not system packages.  Build/runtime
system commands such as Make, Bash, AWK, Graphviz, Bats, Doxygen, ShellCheck, and
shfmt remain outside bashdeps package-management scope.

## Release Artifacts

The generated files are:

```text
dist/figurectl.dev.bash
dist/figurectl.dev.bash.sha256
dist/figurectl.bash
dist/figurectl.bash.sha256
dist/figurectl.min.bash
dist/figurectl.min.bash.sha256
```

All executable flavors represent the same public program and receive the same
observable behavior suite.

The development artifact retains Bash and embedded-AWK documentation.  The
ordinary artifact removes full-line comments while preserving the shebang.  The
minified artifact is derived from the ordinary artifact using prepared
Bash-Minifier state.

Because the Bash artifact contains embedded AWK source, tests must prove that
assembly, comment stripping, and minification preserve behavior rather than
assuming those transformations are harmless.

Release validation and publication are separate jobs under ADR-020.  Validation
runs repository build/dependency/test code with read-only repository-content
authority, including Graphviz-present behavior tests and Bash 4.3 compatibility.
Only after the exact six release files pass validation are they transferred to a
publication job, checksum-verified again, attested, and published.  The publication
job does not check out, rebuild, or synchronize figurectl source.

## Testing

Follow documentation-driven, test-second development under ADR-008.

For consequential behavior:

1. identify or create governing ADR/specification text;
2. write or update source documentation contracts;
3. add focused behavior tests;
4. implement the smallest coherent change;
5. validate all relevant artifact flavors; and
6. compare the result back against the governing constraints.

`tests/figurectl.bats` is the public runtime contract and is executed against the
development, ordinary, and minified artifacts.  `tests/artifacts.bats` validates
artifact/integrity properties, while `tests/compat-bash43.bash` exercises
representative behavior under the compatibility floor.

Tests should cover observable behavior rather than incidental source layout.
Negative assertions are required where the contract says something must not
occur, such as path traversal, unexpected diagnostics on stdout, runtime plugin
discovery, or leakage of non-selected figure representations.

CI additionally executes copied artifacts after removing `src/`, `lib/`,
`scripts/`, and `vendor/` to prove the single-file runtime boundary.

## Security and Threat Modeling

The current project-specific threat model is `doc/threat-model.md`.

Important invariants include:

- build-time discovery is the only plugin discovery;
- generated artifacts execute only built-in assembled implementations;
- figure identifiers are validated before filesystem path construction;
- embedded AWK heredoc delimiters are checked for source collisions;
- temporary AWK program paths are created with `mktemp`;
- DOT/style content is data, not Bash source;
- Graphviz remains a trusted conditional native-code parser rather than a
  sandboxed component;
- release validation does not intentionally receive publication write/OIDC
  authority; and
- transferred release bytes are checksum-verified before attestation and
  publication.

Changes that weaken or expand these boundaries require threat-model review and may
require a new ADR.

## Scope Discipline

Prefer the smallest coherent change that satisfies governing decisions.  Do not
mix unrelated cleanup into implementation work.

The migration preserves observable writing-repository behavior before improving
parser semantics.  Deliberately preserved quirks documented in
`doc/source-extraction.md` should be changed only in focused, reviewable work.

## Repository Locations

- `src/orchestrator.bash`: product-facing command orchestration and entry point.
- `lib/format-registry.bash`: built-in format capability registry.
- `lib/renderers/`: explicitly ordered renderer implementations used by output
  plugins.
- `lib/plugins/input/`: build-discovered authored-source plugins.
- `lib/plugins/output/`: build-discovered requested-output plugins.
- `lib/awk/`: explicitly ordered portable-AWK figure processor and style modules.
- `scripts/build-artifact.bash`: build-only standalone artifact assembler.
- `tests/`: Bats behavior tests and Bash compatibility helper.
- `doc/specification.md`: public figurectl contract.
- `doc/built-in-format-plugins.md`: internal built-in format plugin contract.
- `doc/threat-model.md`: project-specific threat model.
- `doc/release-verification.md`: exact-artifact release and authority contract.
- `doc/decisions.md`: concise Accepted-decision map.
- `doc/adr/`: full architectural decisions.
- `doc/documentation-standard.md`: maintained Bash documentation standard.
- `doc/awk-documentation-standard.md`: maintained AWK documentation standard.
- `doc/reference/`: generated reference documentation; do not commit.
- `vendor/`: generated dependency state; do not commit.
- `dist/`: generated release artifacts; do not edit directly.
- `test-results/`: generated JUnit reports.
