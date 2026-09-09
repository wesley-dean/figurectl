# ADR-019: Adopt the AWK Documentation Standard

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision establishes a normative, AWK-specific source-documentation standard
for maintained AWK in `figurectl` rather than applying Bash documentation rules by
analogy.

The standard is maintained at `doc/awk-documentation-standard.md`.  Generated AWK
reference documentation is produced through the separately maintained
`awk-doxygen` filter, while maintained source remains authoritative.

## Context

`figurectl` extracted a substantial AWK state machine from the original embedded
writing-repository implementation and split it into responsibility-focused source
modules.  The template's Bash documentation standard preserves implementation
contracts well, but AWK has materially different semantics: real function return
values, global-by-default variables, pseudo-local formal parameters, record
context, and first-class `BEGIN`, `END`, and pattern/action rules.

Using Bash terminology mechanically would obscure those differences.  A dedicated
AWK standard therefore defines explicit structural documentation for functions,
parameters, pseudo-locals, significant global state, and anonymous rules.

The documentation contract was adopted before the filter implementation was ready
because maintained source is the source of truth and generated reference output is
derivative.  `awk-doxygen` v0.0.3 now provides a released `doxygen-awk.awk` artifact
covering the documented function, global-state, and rule vocabulary required by
figurectl.  The release artifact is therefore suitable for pinned acquisition
through bashdeps and use alongside, rather than in place of, the existing
`bash-doxygen` filter.

## Decision Drivers

- Document AWK according to AWK semantics rather than Bash analogies.
- Preserve contracts independently of generated-documentation tooling.
- Make record context, global state, and rule triggers explicit.
- Keep portability claims reviewable.
- Generate AWK reference material from the same maintained source used at runtime.
- Preserve separate language-specific filters rather than overloading the Bash
  filter with AWK semantics.
- Keep documentation dependency acquisition inside the existing bashdeps/network
  boundary.
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

The repository SHALL acquire a pinned `doxygen-awk.awk` release artifact through
bashdeps and SHALL use that filter for maintained `*.awk` files during `make docs`.
The existing `bash-doxygen` dependency SHALL remain responsible for maintained
Bash source.  Doxygen configuration SHALL therefore use language-specific filter
patterns rather than replacing one filter with the other.

AWK source SHALL be mapped to the Doxygen-facing C++ representation expected by
`awk-doxygen`; this mapping is an indexing technique, not a claim that maintained
AWK source is C++.

`make docs` SHALL consume prepared `bash-doxygen` and `awk-doxygen` state and SHALL
NOT synchronize either dependency itself.  Missing prepared filters SHALL produce
an actionable failure directing the maintainer to `make deps` or `make all`.

Generated AWK documentation remains derivative.  A filter defect or generated
output disagreement MUST NOT silently redefine the maintained AWK documentation
contract.

## Promises

1. AWK documentation uses language-appropriate contracts.
2. Maintained source, not generated filter output, remains authoritative.
3. Portability assumptions are explicit.
4. Function return values remain distinct from process exit status and stream
   output.
5. Record context, global state, command/file boundaries, and important rule
   ordering are documented when relevant.
6. `make docs` includes maintained AWK source through a pinned AWK-specific filter.
7. Bash and AWK documentation filters remain independent language-specific tools.

## Non-Promises

1. This decision does not claim `awk-doxygen` is a complete AWK parser.
2. Generated reference output does not supersede maintained AWK comments or ADRs.
3. It does not make all transient AWK variables documentation-worthy.
4. It does not create privacy or encapsulation guarantees that AWK does not
   provide.
5. It does not define a particular AWK implementation as the runtime baseline.
6. Mapping filtered AWK output to C++ for Doxygen indexing does not imply C++
   execution semantics or static typing for AWK.

## Adversary and Failure Model

The primary source-documentation risks are maintainers or automated tools
misunderstanding compact AWK semantics: confusing pseudo-locals with public
parameters, overlooking global state, treating current-record access as additional
input, missing `getline` side effects, confusing function returns with process
exits, or accidentally introducing implementation-specific behavior while
continuing to claim portability.

The generated-documentation path adds a dependency boundary.  A compromised or
incorrect `awk-doxygen` artifact could misrepresent source in generated reference
output or execute with the authority of the documentation-generation process.
The artifact is therefore pinned and digest-verified through bashdeps, remains part
of the documentation trusted computing base under ADR-015, and does not become a
runtime dependency of released figurectl artifacts.

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
- `awk-doxygen` MUST be acquired as pinned, digest-verified repository dependency
  state through bashdeps.
- `make docs` MUST use `bash-doxygen` for Bash and `awk-doxygen` for AWK rather
  than replacing one language filter with the other.
- `make docs` MUST consume prepared filter state and MUST NOT synchronize
  dependencies.
- Generated documentation MUST remain derivative of maintained source.

## Considered Alternatives

### Apply the Bash documentation standard and filter to AWK

Rejected because it would encourage shell-specific concepts such as exit-status
`@retval` semantics and would fail to model AWK record/rule/global behavior
accurately.  The existence of a Bash-aware Doxygen filter is not a reason to make
AWK pretend to be Bash.

### Wait for awk-doxygen before documenting AWK

Rejected when the standard was adopted because documentation is part of maintained
architecture and should precede implementation under ADR-008.  Tool availability
does not determine the source contract.  The later arrival of a suitable released
filter now allows generated reference output to catch up with the already-governed
source documentation.

### Replace bash-doxygen with awk-doxygen

Rejected because figurectl contains maintained source in both languages.  The two
filters solve different source-recognition problems and coexist cleanly through
Doxygen's per-file-pattern filtering.

### Use ordinary prose comments without a structural standard

Rejected because the project deliberately values consistent, machine-indexable
contracts and needs explicit vocabulary for AWK-specific semantics.

## Consequences

AWK source is substantially more verbose than the original embedded program.  That
is intentional.  The development artifact retains source documentation while
ordinary/minified consumer representations can remain compact under ADR-006.

The documentation dependency surface now includes both `bash-doxygen` and
`awk-doxygen`.  A prepared documentation build can generate reference material for
both maintained languages without changing the runtime dependency set of released
figurectl artifacts.

Doxygen configuration becomes slightly more explicit because each language has its
own file pattern, filter, and extension mapping.  That explicitness is preferable
to a wrapper that hides which parser owns which source language.

## Source Lineage

The AWK Documentation Standard was provided for this project family on
2026-09-09 and is modeled after the existing Bash documentation philosophy while
explicitly adapting it to AWK execution semantics.  The `awk-doxygen` project was
then developed from the same documentation-led approach and provides the released
filter used by figurectl.

## Superseded Decisions

None.

ADR-007 continues to govern maintained Bash source.  This ADR complements it for
AWK rather than replacing it.  ADR-010 continues to govern generated documentation
as ephemeral derivative output; this ADR extends that generated-documentation path
to maintained AWK source.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-007: Doxygen-Based Verbose Source Documentation Standard
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
- ADR-017: Figure Source Representation and Processing Pipeline
- ADR-018: Build-Time Input and Output Plugin Architecture
