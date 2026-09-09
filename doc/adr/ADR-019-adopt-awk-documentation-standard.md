# ADR-019: Adopt the AWK Documentation Standard

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision establishes a normative, AWK-specific source-documentation standard
for maintained AWK in `figurectl` rather than applying Bash documentation rules by
analogy.

The standard is maintained at `doc/awk-documentation-standard.md` and is designed
for the emerging `awk-doxygen` filtering model.

## Context

`figurectl` will extract a substantial AWK state machine from the original embedded
writing-repository implementation and split it into responsibility-focused source
modules.  The template's Bash documentation standard preserves implementation
contracts well, but AWK has materially different semantics: real function return
values, global-by-default variables, pseudo-local formal parameters, record
context, and first-class `BEGIN`, `END`, and pattern/action rules.

Using Bash terminology mechanically would obscure those differences.  A dedicated
AWK standard now exists and defines explicit structural documentation for functions,
parameters, pseudo-locals, significant global state, and anonymous rules.

The `awk-doxygen` filter is being developed in parallel.  The documentation
contract should not wait for the filter implementation because maintained source is
the source of truth and generated reference output is derivative.

## Decision Drivers

- Document AWK according to AWK semantics rather than Bash analogies.
- Preserve contracts before behavior-preserving extraction begins.
- Make record context, global state, and rule triggers explicit.
- Keep portability claims reviewable.
- Support future generated Doxygen reference material without making the filter the
  source of documentation semantics.
- Preserve enough context for human and AI-assisted maintenance.

## Decision

All maintained AWK source in `figurectl` SHALL follow
`doc/awk-documentation-standard.md`.

The standard's `##` Doxygen comment syntax and structural vocabulary SHALL be
normative, including:

- `@file` for file-level documentation;
- `@fn` for named AWK functions;
- `@param` for caller-supplied formals;
- `@local` for conventional omitted formals used as local storage;
- `@var` for significant project-owned global variables or arrays; and
- `@rule` for documented `BEGIN`, `END`, and pattern/action rules.

Every maintained AWK function SHALL document exactly one `@par STDIN`, one
`@par STDOUT`, one `@par STDERR`, and one `@returns`, as required by the standard.

Documented rules SHALL include exactly one `@par Trigger` and SHALL document
observable output and material side effects as applicable.

Unless another accepted decision states otherwise, maintained AWK SHALL be treated
as portable AWK.  Implementation-specific dependencies MUST be called out rather
than hidden behind an inaccurate portability claim.

The project SHALL NOT delay compliant source documentation merely because the
`awk-doxygen` filter is not yet available.  When the filter becomes a prepared
repository dependency, documentation generation may be extended to include AWK
reference output under the existing dependency/network boundary.

## Promises

1. AWK documentation uses language-appropriate contracts.
2. Maintained source, not generated filter output, remains authoritative.
3. Portability assumptions are explicit.
4. Function return values remain distinct from process exit status and stream
   output.
5. Record context, global state, command/file boundaries, and important rule
   ordering are documented when relevant.

## Non-Promises

1. This decision does not claim `awk-doxygen` is a complete AWK parser.
2. It does not require generated reference documentation to exist before the
   filter is ready.
3. It does not make all transient AWK variables documentation-worthy.
4. It does not create privacy or encapsulation guarantees that AWK does not
   provide.
5. It does not define a particular AWK implementation as the runtime baseline.

## Adversary and Failure Model

The primary risks are maintainers or automated tools misunderstanding compact AWK
semantics: confusing pseudo-locals with public parameters, overlooking global
state, treating current-record access as additional input, missing `getline`
side effects, confusing function returns with process exits, or accidentally
introducing implementation-specific behavior while continuing to claim
portability.

Security-sensitive parsing, regular-expression interpretation, file access, and
command execution require explicit documentation of trust and interpretation
boundaries.

## Operational Constraints

- Maintained AWK MUST follow `doc/awk-documentation-standard.md`.
- AWK Doxygen lines MUST use exactly two leading hash characters.
- Maintained AWK files MUST have `@file`, `@brief`, and substantive `@details`.
- Maintained AWK functions MUST document parameters, relevant locals, stream
  behavior, and AWK return semantics according to the standard.
- Significant rules SHOULD use stable `@rule` documentation identities.
- Portable AWK MUST remain the default portability claim unless a governing
  decision changes it.
- Implementation-specific behavior MUST be documented explicitly.
- Generated documentation MUST remain derivative of maintained source.

## Considered Alternatives

### Apply the Bash documentation standard to AWK

Rejected because it would encourage shell-specific concepts such as exit-status
`@retval` semantics and would fail to model AWK record/rule/global behavior
accurately.

### Wait for awk-doxygen before documenting AWK

Rejected because documentation is part of maintained architecture and should
precede implementation under ADR-008.  Tool availability does not determine the
source contract.

### Use ordinary prose comments without a structural standard

Rejected because the project deliberately values consistent, machine-indexable
contracts and needs explicit vocabulary for AWK-specific semantics.

## Consequences

AWK source will be substantially more verbose than the original embedded program.
That is intentional.  The development artifact retains source documentation while
ordinary/minified consumer representations can remain compact under ADR-006.

When `awk-doxygen` becomes available, the project may add it through bashdeps and
extend `make docs` without redefining source documentation semantics.

## Source Lineage

The AWK Documentation Standard was provided for this project family on
2026-09-09 and is modeled after the existing Bash documentation philosophy while
explicitly adapting it to AWK execution semantics.

## Superseded Decisions

None.

ADR-007 continues to govern maintained Bash source.  This ADR complements it for
AWK rather than replacing it.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-007: Doxygen-Based Verbose Source Documentation Standard
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-017: Figure Source Representation and Processing Pipeline
- ADR-018: Build-Time Input and Output Plugin Architecture
