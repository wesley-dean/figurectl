# ADR-021: Publish Ephemeral ADR Navigation as the Reference Landing Page

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision refines the generated-reference-documentation model established by
ADR-010 so the Architecture Decision Record landing page is assembled during the
documentation build rather than maintained as a manually synchronized index.

The durable documentation surfaces remain the ADRs themselves plus maintained
introductory and concluding prose.  The linked list of ADRs is derived state and
should be regenerated from the current ADR corpus by the same documentation
workflow that publishes the Doxygen site.

This decision also records the security review required by ADR-015 and ADR-016
for the new `adrctl` documentation dependency.

## Context

figurectl already includes `doc/adr` in Doxygen input and already uses
`doc/adr/README.md` as `USE_MDFILE_AS_MAINPAGE`.  That arrangement gives the
published GitHub Pages site a useful architecture-oriented landing page, but the
README currently contains a manually maintained ADR index.

A manually maintained index duplicates information that can be derived from the
ADR corpus.  Every ADR addition creates another synchronization obligation: the
ADR file, `doc/decisions.md`, and the ADR README index can disagree even when the
underlying decisions are correct.

Related repositories have adopted an `adrctl generate toc` workflow that produces
linked ADR navigation from the current repository state.  A first iteration of
that pattern committed the generated README and then used CI to detect drift.
That model works, but it makes a derivative file part of review history and adds a
second synchronization requirement: generated output must be regenerated and
committed whenever its maintained inputs change.

figurectl already has a stronger governing principle in ADR-010: generated
reference documentation is ephemeral and should be rebuilt from maintained source.
Applying that principle to the ADR landing page removes the remaining generated
Markdown synchronization burden while preserving the useful Pages experience.

The repository also has an explicit dependency and threat-modeling posture.  ADR-005
requires ordinary repository dependencies to be declared in `dependencies.txt`
and prepared through bashdeps.  ADR-015 requires every new dependency to be
reviewed as additional trusted code.  ADR-016 and `doc/threat-model.md` require
review when documentation tooling or dependency trust changes.

## Decision Drivers

- Preserve a useful architecture-oriented GitHub Pages landing page.
- Generate linked ADR navigation from the current ADR corpus rather than maintain
  duplicate index entries by hand.
- Keep generated Markdown derivative and disposable under the same philosophy as
  generated Doxygen HTML.
- Preserve the existing explicit dependency and network boundaries.
- Reuse the repository's existing `dependencies.txt` and bashdeps lifecycle rather
  than introduce a second documentation dependency mechanism.
- Make local and CI documentation generation use the same Make targets.
- Generate the landing page atomically so a failed TOC generation does not leave a
  partially replaced README.
- Preserve the existing Bash and AWK Doxygen filters and their language-specific
  responsibilities.
- Keep ADR relationship graphs out of routine documentation generation.
- Preserve figurectl's legitimate Graphviz runtime/rendering behavior and its
  maintained threat-model diagrams independently from ADR navigation.

## Decision

### Maintained ADR framing is split from generated navigation

The repository SHALL maintain these source surfaces:

```text
doc/adr/README.intro.md
doc/adr/ADR-*.md
doc/adr/README.outro.md
```

`README.intro.md` SHALL contain the maintained framing that belongs before the
generated ADR list.  `README.outro.md` SHALL contain maintained explanatory prose
that belongs after the generated list.

The generated composite SHALL remain:

```text
doc/adr/README.md
```

The composite README SHALL be ignored by Git and SHALL NOT be committed as
maintained source.

The generated structure is conceptually:

```text
# Architecture Decision Records

README.intro.md

linked ADR list generated from the current corpus

README.outro.md
```

The heading and list serialization are owned by adrctl.  The framing files SHALL
therefore not duplicate the generated top-level heading.

### adrctl becomes a pinned documentation dependency

The released `adrctl.bash` artifact SHALL be declared in the existing
`dependencies.txt` manifest and synchronized by bashdeps under ADR-005.

The initial selected release for this decision is `adrctl` v0.0.14, with the
artifact stored as:

```text
vendor/adrctl.bash
```

The manifest SHALL pin and digest-verify the exact artifact bytes in the same way
as the existing `bash-doxygen`, `awk-doxygen`, and Bash-Minifier dependencies.

Make SHALL NOT add a direct adrctl download rule.  bashdeps remains the only
directly bootstrapped repository dependency manager.

adrctl is documentation tooling only.  It SHALL NOT become an input to the
figurectl runtime artifacts, the embedded AWK program, the build-time input/output
plugin architecture, or Graphviz rendering behavior.

### Make owns the generated ADR landing-page lifecycle

The Makefile SHALL provide an `adr-index` target that consumes already-prepared
`vendor/adrctl.bash` state and generates `doc/adr/README.md`.

`adr-index` SHALL:

1. verify that the prepared adrctl artifact and maintained intro/outro files are
   present;
2. invoke `adrctl generate toc` with the maintained intro and outro;
3. write generation output to a same-directory temporary candidate;
4. replace `doc/adr/README.md` only after successful generation; and
5. remove the temporary candidate after failure.

`adr-index` SHALL NOT run `make deps`, invoke bashdeps synchronization, or
otherwise acquire or repair missing dependency state.

`make docs` SHALL continue to consume prepared repository dependency state.  It
SHALL require the Bash Doxygen filter, AWK Doxygen filter, and adrctl artifact to
be present before documentation generation begins.  After cleaning old generated
documentation state, it SHALL generate the current ADR landing page and then run
Doxygen.

`docs-clean` SHALL remove both generated documentation layers:

```text
doc/adr/README.md
doc/reference/
```

`clean` and `distclean` SHALL retain their existing broader lifecycle semantics.

### Doxygen continues to use the generated README as its main page

The Doxygen main-page path SHALL remain:

```text
USE_MDFILE_AS_MAINPAGE = doc/adr/README.md
```

The ADR corpus SHALL remain part of Doxygen input so individual decisions are
available from the generated navigation.

Maintained framing files and ADR templates/checklists that are not intended as
standalone reference pages SHOULD be excluded from Doxygen input where practical.
The generated README is the navigation surface; the intro and outro are source
fragments used to construct it.

The existing language-specific filter boundary remains unchanged:

- `vendor/doxygen-bash.awk` processes maintained Bash; and
- `vendor/doxygen-awk.awk` processes maintained AWK.

adrctl does not replace or wrap either source filter.

### Routine ADR navigation does not include relationship graphs

`make adr-index`, `make docs`, and the Pages workflow SHALL generate linked textual
ADR navigation only.  They SHALL NOT invoke `adrctl generate graph` or compose an
ADR relationship graph into the landing page.

This does not remove or restrict adrctl's explicit graph command, and it does not
alter figurectl's own Graphviz renderer, DOT figure support, SVG/PNG output,
caller-supplied DOT styling, or threat-model diagrams.  Those are separate product
and documentation concerns governed by other decisions.

### CI and Pages validate generated-state boundaries

The test workflow and Pages workflow SHOULD verify that:

- dependency preparation succeeds before documentation generation;
- `make docs` succeeds from prepared dependency state;
- `make deps-check` still succeeds after documentation generation;
- `doc/adr/README.md` exists and includes the current ADR corpus;
- `doc/adr/README.md` is ignored by Git;
- `doc/reference/index.html` exists and is ignored by Git; and
- documentation generation does not dirty tracked repository state.

Tests SHOULD also preserve the negative network-boundary contract by verifying
that missing adrctl state causes documentation generation to fail without
acquiring dependencies.

## Dependency and Threat-Model Review

Adding `adrctl` expands the documentation trusted computing base and therefore
requires explicit review under ADR-015 and ADR-016.

### Execution context

adrctl executes as a subprocess during `make adr-index` and transitively during
`make docs`.  It does not execute in released figurectl artifacts.

### Data exposure

adrctl reads the maintained ADR corpus and the maintained intro/outro framing
files.  These are repository documentation, not runtime caller input or secrets.
It writes generated Markdown under `doc/adr/`.

### Authority

adrctl inherits the local or CI documentation process's ordinary filesystem and
environment authority.  It does not require GitHub publication credentials,
release authority, or runtime application privileges to perform TOC generation.
The Pages job already possesses Pages publication authority because it publishes
Doxygen output; adrctl therefore becomes additional executable code in that
workflow and must remain pinned and digest verified.

### Input trust

The ADR corpus is repository-controlled Markdown.  Pull-request content can
influence that input before merge, so CI must continue to treat documentation
execution as code/tool execution rather than as a harmless formatting step.

### Side effects

For this integration, adrctl is invoked only for report generation to stdout.
Make owns the generated destination and atomic replacement.  The integration does
not invoke adrctl mutation commands.

### Transitive and supply-chain surface

The selected artifact is a released standalone adrctl executable pinned by version
and SHA-256 digest through bashdeps.  No new runtime dependency, package manager,
network service, plugin path, or direct acquisition mechanism is introduced.

### Failure behavior

Missing or invalid dependency state causes the existing explicit preparation or
verification boundary to fail.  A failed TOC generation does not replace the
existing generated README because output is staged to a temporary candidate.

### Removal cost and alternatives

The coupling is deliberately small: one manifest entry, one Make target, and the
stable `generate toc` command.  Removing adrctl later would require replacing only
that generated-navigation mechanism, not figurectl runtime behavior.

The principal alternative is maintaining the index manually.  That avoids one
documentation dependency but preserves duplicated derived state and its drift
risk.  Given adrctl is already a reviewed tool in this project family and is used
only within the existing documentation boundary, the additional trusted code is
accepted.

`doc/threat-model.md` SHALL be updated to include adrctl in the documentation
trusted computing base and generated-documentation data flow.  Existing Graphviz
and runtime threat boundaries remain unchanged.

## Promises

1. The published reference landing page is generated from the current ADR corpus.
2. Maintained intro/outro prose remains reviewable source rather than generated
   content.
3. The generated ADR README and Doxygen HTML remain uncommitted derivative state.
4. Documentation generation remains offline and non-repairing after explicit
   dependency preparation.
5. adrctl is pinned and digest verified through the existing bashdeps manifest.
6. Failed ADR-index generation does not publish a partial replacement README.
7. Bash and AWK Doxygen filtering remain independent language-specific paths.
8. Routine documentation generation does not add an ADR relationship graph.
9. Figurectl runtime, Graphviz rendering, and released artifact behavior do not
   depend on adrctl.

## Non-Promises

1. The repository no longer promises a browsable generated ADR index directly in
   the GitHub source tree without running the documentation-generation step.
2. The generated README is not an independent maintained source of architectural
   truth.
3. Digest verification does not prove adrctl is behaviorally safe; it proves the
   selected bytes match the reviewed manifest declaration.
4. This decision does not change adrctl's public report formats or graph support.
5. This decision does not change figurectl's figure-processing, Graphviz, plugin,
   runtime, release, or compatibility contracts.
6. This decision does not make all documentation under `doc/` part of the Doxygen
   site; Doxygen input remains deliberately scoped.

## Adversary and Failure Model

This decision considers:

- a new ADR being added while a manually maintained index is forgotten;
- generated Markdown being committed and drifting from its source inputs;
- a missing or tampered adrctl artifact being silently repaired by `make docs`;
- partial generated README output being left behind after a failed command;
- a compromised documentation dependency influencing published Pages content or
  acting with the documentation workflow's authority;
- accidental expansion of adrctl into figurectl runtime or release artifacts;
- accidental replacement of the Bash/AWK Doxygen filters with a generic wrapper;
- routine documentation generation reintroducing an ADR relationship graph; and
- unrelated Graphviz product behavior being confused with ADR navigation policy.

The integration does not attempt to sandbox adrctl.  Pinning, digest verification,
least-purpose invocation, offline generation after preparation, generated-state
isolation, and CI validation are the selected mitigations.

## Operational Constraints

- `vendor/adrctl.bash` MUST be declared in `dependencies.txt` and managed by
  bashdeps.
- `make adr-index` MUST consume prepared dependency state and MUST NOT synchronize
  dependencies.
- `make docs` MUST remain offline and non-repairing after dependency preparation.
- `doc/adr/README.intro.md` and `doc/adr/README.outro.md` MUST be maintained source.
- `doc/adr/README.md` MUST be generated state and MUST NOT be committed.
- ADR index generation MUST use a temporary candidate and atomic replacement.
- `docs-clean` MUST remove the generated ADR README and Doxygen output.
- Doxygen MUST continue to use the generated ADR README as its main page.
- Bash and AWK MUST continue to use their separate prepared Doxygen filters.
- Routine documentation generation MUST NOT invoke or embed an ADR relationship
  graph.
- Figurectl Graphviz rendering and threat-model diagram behavior MUST remain
  independent of ADR navigation generation.
- The project threat model MUST include adrctl in the documentation dependency
  boundary.

## Considered Alternatives

### Keep the manually maintained ADR index

This avoids another documentation dependency but retains duplicate information and
requires every ADR change to synchronize an index that can be derived
mechanically.  It was rejected because the repository already accepts generated
reference material and has a suitable pinned tool for generating the navigation.

### Generate and commit `doc/adr/README.md`

This preserves a convenient source-tree index on GitHub and makes the generated
file visible without running Make.  It was rejected because it creates a generated
artifact that must be regenerated, reviewed, committed, and checked for drift even
though the published documentation workflow can build it directly from maintained
inputs.

### Generate the ADR landing page outside `doc/adr`

A separate build-input directory would create an especially clean maintained-versus-generated
filesystem boundary.  It was not selected because figurectl already uses
`doc/adr/README.md` as the Doxygen main page, and an ignored generated README in
that directory preserves the existing Doxygen contract with less configuration
change.  The ownership boundary is made explicit through Git ignore rules and Make
cleanup.

### Add a documentation-specific dependency manifest

Rejected because ADR-005 already establishes `dependencies.txt` as the repository
dependency source of truth.  adrctl fits that contract cleanly, and a second
manifest would add orchestration without a different trust or lifecycle need.

### Reimplement TOC generation in Make, awk, or shell

This would avoid the adrctl dependency but duplicate ADR discovery, title parsing,
ordering, and link generation semantics already owned and tested by adrctl.  The
small reduction in dependency count does not justify creating a second ADR parser
inside figurectl's documentation build.

### Include an ADR relationship graph

Rejected for routine documentation generation.  A linked textual index provides
the navigation needed by the published site without adding graph composition,
renderer/version concerns, or another derived visualization.  Explicit graph
generation remains available from adrctl when a maintainer deliberately wants it.

## Consequences

The tracked ADR README disappears from repository history and becomes reproducible
build input for Doxygen.  Maintainers edit the intro/outro fragments and ADRs
instead of a generated index.

A fresh checkout must prepare adrctl through `make deps` before `make adr-index` or
`make docs` can succeed.  This is consistent with the existing requirement for
prepared Bash/AWK documentation filters.

The documentation trusted computing base grows by one pinned executable.  The
project threat model records that addition.  Runtime and release-artifact trusted
computing bases do not grow.

CI gains stronger evidence that both generated documentation layers are disposable
and ignored.  Pages continues to publish `doc/reference/` from the exact source
revision being built.

## Source Lineage

This decision adapts the ephemeral ADR landing-page pattern established in related
Bash repositories, including adrctl, bash-doxygen, awk-doxygen, bashdeps, bashlog,
and Bootstrap.  The figurectl variant preserves its existing dual Bash/AWK
Doxygen-filter architecture and its stronger explicit dependency/threat-model
review requirements.

## Superseded Decisions

None.

ADR-010 remains in force and is refined by this decision.  Its requirement that
generated reference documentation be ephemeral now explicitly includes the
assembled Markdown main page used as Doxygen input.

ADR-005 remains authoritative for dependency acquisition.  ADR-015 and ADR-016
remain authoritative for dependency trust and threat-model review.  ADR-019
continues to govern AWK documentation and the separate `awk-doxygen` filter.

## Related Decisions

- ADR-001: Documentation and Decision Hierarchy
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-007: Doxygen-Based Verbose Source Documentation Standard
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-013: Repository-Facing Documentation and Template Hygiene
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
- ADR-017: Figure Source Representation and Processing Pipeline
- ADR-018: Build-Time Input and Output Plugin Architecture
- ADR-019: Adopt the AWK Documentation Standard
- ADR-020: Separate Release Validation from Publication Authority
