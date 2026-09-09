# ADR-018: Build-Time Input and Output Plugin Architecture

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision establishes a generalized internal extension architecture for
`figurectl` while preserving its standalone single-file runtime contract.

The word "plugin" in this ADR means a maintained project module discovered and
assembled during the build.  It does not mean an external runtime extension,
third-party installation mechanism, or dynamically loaded file.

## Context

The original writing-repository implementation intentionally avoided a generalized
renderer/plugin framework because only text and DOT source plus text, DOT, SVG,
and PNG output were required.  That was a reasonable constraint for a local script.

As `figurectl` becomes a standalone reusable product, input/output format handling
benefits from explicit internal contracts.  New built-in formats should be
additive rather than requiring format-specific branches throughout parsing,
selection, rendering, and replacement logic.

At the same time, the project deliberately distributes one self-contained Bash
artifact.  Runtime filesystem scanning or dynamic sourcing would create a new
trust boundary, make deployed behavior depend on local filesystem state, and
complicate compatibility and release verification.

The template repository already distinguishes deterministic build-time discovery
from runtime plugin architecture.  `figurectl` adopts that distinction directly.

## Decision Drivers

- Keep maintained source modular and responsibility-focused.
- Make adding a built-in format additive where practical.
- Keep semantically important core ordering explicit.
- Avoid distributed `case` statements that each know every supported format.
- Preserve deterministic and reviewable build output.
- Preserve standalone `.bash` release artifacts.
- Avoid runtime dynamic loading and the associated trust boundary.
- Keep the initial public format set compatible with the writing implementation.

## Decision

### Plugin discovery occurs only during build

Input and output plugin modules SHALL be discovered from maintained repository
source during the build process.

Discovery SHALL be deterministic.  Lexical pathname ordering MAY be used for peer
modules whose relative order has no semantic meaning.

Core source whose ordering reflects dependencies SHALL remain explicitly ordered.
Semantic dependencies MUST NOT be encoded only through incidental plugin filename
ordering.

### Released artifacts contain all built-in implementations

The build SHALL assemble selected input/output modules into each generated
`figurectl` executable artifact.

Released artifacts SHALL NOT require the maintained source tree, plugin
directories, `vendor/`, Make, bashdeps, or other build-time state during normal
runtime use.

### No external runtime plugin support

The initial project SHALL NOT:

- scan runtime directories for plugins;
- source implementation files supplied after build;
- hot-load format implementations;
- define a third-party plugin installation location;
- accept arbitrary plugin search paths; or
- claim a stable external plugin ABI/API.

Adding any such capability requires a new architectural decision covering trust,
compatibility, discovery precedence, failure semantics, version negotiation, and
release/support implications.

### Input and output responsibilities are distinct

Authored source formats and requested output formats SHALL remain separate
concepts.

Input/source modules describe capabilities needed to recognize and process an
authored representation.  Output modules describe capabilities needed to
materialize or replace the selected representation for a requested publication
format.

The exact Bash/AWK function names are implementation details to be established by
source documentation and tests.  This ADR governs the responsibility boundary,
not a prematurely frozen internal function ABI.

### Capability-oriented dispatch

Core orchestration SHOULD ask registered/discovered implementations for relevant
capabilities rather than distribute format-name branching throughout unrelated
layers.

A format implementation may declare that it:

- consumes a particular authored source representation;
- materializes a particular file extension;
- requires a renderer or other conditional system capability;
- emits a fenced block or a Markdown image reference; or
- supports caller-supplied rendering policy such as Graphviz styling.

The initial public mapping remains governed by ADR-017 and the project
specification.

### Initial v1.0 built-ins

The v1.0 implementation SHALL provide built-in support for authored source:

```text
text
dot
```

and requested output:

```text
text
dot
svg
png
```

This generalized internal architecture does not expand the v1.0 public format set
by itself.

## Promises

1. Built-in format modules can be maintained separately from the core parser and
   orchestrator.
2. Plugin discovery is deterministic and occurs before release artifacts are
   produced.
3. Every released artifact contains the implementations it supports.
4. Runtime behavior does not depend on a plugin directory or external extension
   state.
5. Core semantic ordering remains explicit.
6. The public format set remains a deliberate compatibility decision rather than
   whatever files happen to exist in a source directory.

## Non-Promises

1. The project does not provide a third-party plugin API in v1.0.
2. Plugin filenames do not define a public runtime ABI.
3. Lexical build ordering does not permit peer plugins to depend on incidental
   ordering.
4. Modular source does not imply multiple runtime files.
5. Generalized internal dispatch does not mean every conceivable renderer or
   format should be supported.

## Adversary and Failure Model

This decision addresses accidental architecture drift, hidden format coupling,
nondeterministic assembly, and runtime extension risk.

Maintained plugin source committed to the repository is trusted project code and
passes through ordinary review, tests, build transformations, and release
verification.  External third-party plugin code is outside the supported runtime
model and is not granted a loading path.

Build discovery must fail predictably when source layout violates declared
constraints.  Runtime dispatch must fail clearly when a requested format is not
contained in the built artifact rather than attempting filesystem discovery or
fallback execution.

## Operational Constraints

- Plugin discovery MUST occur only during build.
- Discovery MUST be deterministic.
- Core semantic source order MUST be explicit.
- Peer plugin ordering MUST NOT carry hidden semantic dependencies.
- Generated artifacts MUST remain standalone.
- Runtime directory scanning and dynamic sourcing MUST NOT be introduced without
  a new ADR.
- v1.0 MUST contain text and DOT source support plus text, DOT, SVG, and PNG
  output support.
- Public format support MUST be documented and tested rather than inferred from
  source-directory contents alone.

## Considered Alternatives

### Keep all format dispatch in central case statements

This would preserve the original local-script shape.  It was rejected for the
standalone project because each new built-in format would require coordinated
changes across unrelated dispatch points and would weaken separation of concerns.

### Discover and source plugins at runtime

Rejected because it would weaken standalone distribution, add filesystem and code
execution trust boundaries, and make release verification insufficient to describe
what code actually executes after deployment.

### Define a third-party plugin API immediately

Rejected because no current consumer requires it.  Designing version negotiation,
compatibility policy, trust rules, discovery precedence, and installation
semantics without a real use case would expand public surface prematurely.

### Explicitly enumerate every built-in format file

Acceptable for semantically ordered core modules but rejected as the default for
additive leaf implementations.  Deterministic build-time discovery better matches
the desired extension model while retaining inspectability.

## Consequences

The maintained project gains internal extensibility and clearer responsibility
boundaries while runtime remains a single file.  Build/test logic must validate
that discovery, assembly, comment stripping, and minification preserve all built-in
implementations.

The project intentionally diverges from the original writing ADR's decision not to
build a generalized plugin framework.  That earlier choice remains historically
correct for the local writing script; this ADR records why the standalone product
now makes a different decision.

## Source Lineage

This decision is informed by template-bash ADR-004 and ADR-014 and by the
experience of the writing-repository `figurectl.bash` implementation.

## Superseded Decisions

None within `figurectl`.

This ADR intentionally does not supersede writing ADR-035 because that ADR governs
a different repository and preserves the historical reasoning of the local tool.

## Related Decisions

- ADR-004: Modular Source Assembly and Automatically Discovered Plugins
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-014: Modularity as Maintenance and Assembly Architecture
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
- ADR-017: Figure Source Representation and Processing Pipeline
