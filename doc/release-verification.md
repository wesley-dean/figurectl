# Release Verification

The release pipeline calculates a semantic version from Conventional Commits
without creating a tag, validates the exact bytes intended for publication, and
creates the GitHub release/tag only after validation succeeds.

Release validation and publication are separate trust boundaries.  The validation
job executes repository-controlled build, dependency, renderer, and test code with
read-only repository-content authority.  A later publication job receives the
narrow write, attestation, and OIDC permissions required to publish only after the
validation job succeeds.  See ADR-020.

The expected sequence is:

1. calculate the version with `bitshifted/git-auto-semver` and
   `create_tag: false`;
2. run maintained-source checks;
3. run `make deps` and `make deps-check`;
4. build all artifact flavors with the calculated version;
5. execute the Bats behavior contract against the exact generated artifacts with
   Graphviz available so SVG/PNG behavior is exercised rather than skipped;
6. execute representative compatibility behavior for every generated artifact
   under Bash 4.3;
7. verify that the release set contains exactly the three executable artifacts and
   their three `.sha256` companions, and verify every checksum;
8. upload those exact six files as one transient GitHub Actions workflow artifact;
9. in a separate publication job, download that workflow artifact and verify the
   expected six-file set and checksums again;
10. attest the downloaded release files; and
11. create the GitHub release and tag with all six files attached.

The validation job does not need repository-content write, attestation write,
artifact-metadata write, or OIDC token-minting permission.  The publication job
does not check out the repository, synchronize dependencies, rebuild artifacts, or
execute the project test suite.  This division keeps publication authority away
from the larger build/test execution surface while ensuring that publication uses
the exact bytes that were validated.

The GitHub Actions artifact used between jobs is transient workflow transport.  It
is not a seventh figurectl release artifact and is not a supported consumer
distribution channel.  Upload/download actions used at this boundary are pinned by
commit SHA, and checksum verification occurs after download before attestation or
release creation.

New releases publish only `.sha256` checksum companions.  Historical releases
that contain `.256` companions remain unchanged.  A consumer that verifies
artifacts across release generations should request `<artifact>.sha256` first and
may use `<artifact>.256` only when the preferred companion is confirmed absent.
Transport, TLS, authorization, server, malformed-content, and checksum-verification
failures remain failures rather than fallback conditions.

Published checksum companions are release verification data.  They do not replace
the committed SHA-256 digests that authorize bashdeps or dependencies declared in
`dependencies.txt`.

The Conventional Commit mapping used by the selected SemVer action supports the
full semantic progression: `feat` increments minor, `BREAKING CHANGE` increments
major, and supported maintenance types increment patch.

A release failure before the final step should leave no newly-created release
tag.  This ordering is deliberate: publication is the consequence of successful
validation, not a prerequisite for it.  A failure after attestation but before
release creation may leave attestation records associated with the workflow's
validated files, but it must not create the release tag prematurely.

See ADR-011 for Conventional-Commit release semantics, ADR-012 for checksum
companion naming and historical-read compatibility, ADR-015 for dependency trust,
and ADR-020 for the validation/publication authority boundary.
