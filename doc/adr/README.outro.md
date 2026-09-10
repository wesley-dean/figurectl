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

ADR-021 refines ADR-010 by treating the assembled ADR landing page as ephemeral
Doxygen input.  Maintained framing and ADR source remain authoritative while the
linked navigation and reference HTML are regenerated together from prepared,
digest-verified documentation tooling.
