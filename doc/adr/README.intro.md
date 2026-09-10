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

The linked index below is generated from the current ADR corpus by the pinned
`adrctl` documentation dependency.  This file and `README.outro.md` are maintained
source; the assembled `README.md` used as the Doxygen landing page is generated,
ignored repository state.

## Index
