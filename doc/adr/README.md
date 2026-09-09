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
- A project specification, when needed, describes current observable behavior.
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

ADR-014 refines how derived projects should interpret ADR-004: modular maintained
source and deterministic assembly are reusable architectural lessons, while the
starter's runtime registry and noop plugin remain an example to evaluate rather
than a universal requirement.
