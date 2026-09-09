# Architecture Decision Records

Architecture Decision Records preserve the reasoning behind consequential
technical and process decisions in this project.  They are intentionally more
verbose than operational summaries because context, alternatives, constraints,
and rejected options are part of the architectural record.

The repository uses a layered documentation model:

- `doc/engineering-philosophy.md` records reusable engineering instincts for areas
  where no more specific Accepted ADR governs.
- ADRs explain why durable decisions exist and what constraints follow from
  them.
- `doc/decisions.md` provides a concise discovery map of Accepted decisions.
- `AGENTS.md` is a concise operational map that points back to the governing
  ADRs rather than repeating their reasoning.
- `doc/specification.md` describes the intended observable figurectl contract.
- `doc/threat-modeling.md` provides a reusable exercise for exposing assets, trust
  boundaries, dependency risk, mitigations, and residual risk.
- Doxygen comments preserve local implementation contracts and reasoning near
  the code that depends upon them.
- Tests and CI verify observable behavior and selected architectural invariants.

When the engineering philosophy and an Accepted ADR disagree, the ADR governs.
The philosophy document is guidance, not a second source of binding architecture.

The ADR template includes `Promises`, `Non-Promises`, `Adversary and Failure
Model`, and `Operational Constraints` sections so consequential decisions expose
both what they guarantee and what reasonable readers should not infer.  Those
sections do not replace the surrounding rationale.

## Index

- ADR-000: Capability Scope, Epistemic Honesty, and Separation of Concerns
- ADR-001: Documentation and Decision Hierarchy
- ADR-002: Bash Runtime and Portability Baseline
- ADR-003: Make as the Canonical Orchestration Interface
- ADR-004: Modular Source Assembly and Automatically Discovered Plugins
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-007: Doxygen-Based Verbose Source Documentation Standard
- ADR-008: Documentation-Driven, Test-Second Development
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-010: Generated Reference Documentation Is Ephemeral
- ADR-011: Conventional-Commit Semantic Releases and Late Tagging
- ADR-012: Standardize SHA-256 Checksum Companion Filenames
- ADR-013: Repository-Facing Documentation and Template Hygiene
- ADR-014: Modularity as Maintenance and Assembly Architecture
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
- ADR-017: Figure Source Representation and Processing Pipeline
- ADR-018: Build-Time Input and Output Plugin Architecture
- ADR-019: Adopt the AWK Documentation Standard
- ADR-020: Separate Release Validation from Publication Authority

ADR-014 refines how figurectl interprets the inherited ADR-004: modular maintained
source and deterministic assembly remain reusable architectural lessons, while
runtime registry behavior is product-specific.  ADR-018 then establishes the
figurectl-specific choice: input/output modules are discovered only during build
and are embedded into standalone artifacts; external runtime plugins are not
supported.

ADR-017 is adapted from `wesley-dean/writing` ADR-035.  The writing ADR remains
historical governance for that repository, while figurectl owns the reusable
figure-processing contract going forward.

ADR-020 refines ADR-011's late-tagging release sequence by separating read-only
artifact validation from the narrowly privileged publication job.  Validated
release files cross that boundary through transient GitHub Actions artifact
storage and are checksum-verified again before attestation and release creation.
