# ADR-020: Separate Release Validation from Publication Authority

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision refines the late-tagging release architecture established by
ADR-011.  Release validation and release publication have different authority
requirements and SHALL execute in separate jobs so repository-controlled build,
test, and dependency code does not receive publication credentials merely because
it precedes publication in the same workflow.

## Context

ADR-011 requires figurectl to calculate a version without creating a tag, validate
the exact release artifacts, verify checksums, attest the release files, and create
the GitHub release/tag only after validation succeeds.

The inherited workflow implemented that sequence inside one job.  The job needed
`contents: write`, attestation, artifact-metadata, and OIDC permissions for its
final publication steps.  GitHub Actions job permissions apply to the complete
job, however, so the same authority was present while the job checked out the
repository, synchronized dependencies, executed maintained project code, ran the
pinned Bash-Minifier, invoked Graphviz, and executed tests.

Those earlier steps do not need release authority.  Giving them that authority
unnecessarily expands the blast radius of a compromised repository dependency,
build helper, test path, renderer, or other code executed during validation.

A separate validation job can remain read-only, produce the exact six files that
passed the release contract, and transfer those files to a narrowly privileged
publication job through a named GitHub Actions workflow artifact.  The publication
job can then verify the transferred bytes again before attestation and release.

## Decision Drivers

- Preserve ADR-011 late tagging and exact-artifact validation.
- Minimize the code that executes with release/tag and OIDC authority.
- Keep repository scripts and synchronized dependencies out of the publication
  trust boundary where practical.
- Ensure the bytes published are the bytes that passed validation.
- Make inter-job artifact transport explicit and verifiable.
- Avoid introducing an external release service or long-lived credential.
- Prevent manual dispatch from turning an arbitrary development ref into a
  releasable source revision.
- Keep the workflow understandable and auditable.

## Decision

### Validation and publication are separate jobs

The release workflow SHALL use a validation job and a publication job.

The release path SHALL execute only for the repository's `main` ref.  Automatic
push execution is limited to `main`, and a manually dispatched workflow from
another ref SHALL NOT validate or publish a release.  Development branches may be
validated through ordinary pull-request CI without gaining a release path merely
because `workflow_dispatch` exists.

The validation job SHALL have read-only repository-content permission.  It SHALL:

1. check out the target commit with sufficient history/tags for semantic-version
   calculation;
2. calculate the next version with `bitshifted/git-auto-semver` and
   `create_tag: false`;
3. run maintained-source validation;
4. synchronize and verify repository dependencies;
5. build all release artifacts using the calculated version;
6. run the complete behavior suite against those exact generated artifacts;
7. run representative behavior against every artifact under Bash 4.3;
8. verify the exact six-file release set and every `.sha256` companion; and
9. upload those six files as one named workflow artifact for the publication job.

The validation job SHALL NOT receive repository-content write, attestation write,
artifact-metadata write, or OIDC token-minting permission merely to prepare release
bytes.

### Publication authority is granted only after validation

The publication job SHALL depend on successful completion of the validation job.
It SHALL NOT check out the repository or rerun project build/dependency code.

The publication job MAY receive only the permissions required to retrieve the
validated workflow artifact, attest the release files, and create the GitHub
release/tag.  It SHALL:

1. download the named validation artifact;
2. verify the expected six-file set and `.sha256` companions again after
   inter-job transport;
3. attest the release files; and
4. create the release/tag targeting the validated workflow commit.

The release/tag creation step SHALL remain last.  A failed validation,
download, checksum verification, or attestation SHALL NOT create a new release
tag.

### Workflow artifact is transport, not a release product

The named GitHub Actions artifact used between jobs is transient workflow state.
It is not an additional figurectl release artifact and does not expand the
six-file public release contract from ADR-006 and ADR-012.

The workflow artifact SHALL contain only:

```text
figurectl.dev.bash
figurectl.dev.bash.sha256
figurectl.bash
figurectl.bash.sha256
figurectl.min.bash
figurectl.min.bash.sha256
```

Upload/download actions used for this transport SHALL be pinned to reviewed commit
SHAs under the project's ordinary dependency/supply-chain policy.

### Release validation must not silently skip graphical behavior

Because SVG and PNG are v1.0 public outputs, the release validation environment
SHALL provide Graphviz so graphical tests execute rather than being skipped merely
because `dot` is absent from the release runner.

The Bash 4.3 compatibility job remains representative rather than exhaustive; the
complete public behavior matrix continues to run in the primary validation
environment.

## Promises

1. Repository build/test code does not intentionally receive GitHub release write
   or OIDC publication authority during release validation.
2. A release tag is created only after validation, inter-job checksum verification,
   and attestation succeed.
3. The publication job operates on the validated six-file artifact set rather
   than rebuilding release files independently.
4. SVG and PNG behavior is exercised in release validation with Graphviz present.
5. Inter-job workflow-artifact transport is followed by checksum verification
   before publication.
6. A manual dispatch from a non-`main` ref does not become a release path.

## Non-Promises

1. Job separation does not prove that build dependencies cannot produce malicious
   artifact content.  They remain trusted build inputs under ADR-015.
2. Checksums prove byte identity relative to the generated sidecars; they do not
   prove that the program is safe or semantically correct.
3. GitHub-hosted runners, GitHub Actions artifact storage, pinned third-party
   actions, and the GitHub release service remain within the release trusted
   computing base.
4. This decision does not introduce reproducible builds across unrelated hosts or
   independently rebuilt attestations.
5. The transient workflow artifact is not a supported consumer distribution
   channel.

## Adversary and Failure Model

This decision considers:

- compromised or malicious repository dependency code executing during
  `make deps`, build, tests, or minification;
- a project script unintentionally mutating repository or release state because
  the enclosing job possesses write authority;
- a compromised Graphviz or other validation subprocess inheriting more GitHub
  authority than its task requires;
- a maintainer accidentally dispatching release automation from a development
  branch;
- validation succeeding but inter-job artifact transport producing missing or
  altered files;
- publication steps running with stale or independently rebuilt bytes;
- attestation failure after successful validation; and
- release creation failing after attestation.

Separating jobs reduces publication authority available to validation code but
does not remove the build supply chain from the trusted computing base.  A
compromised build dependency can still influence the bytes that validation tests
and uploads.  The mitigation is narrower authority, exact-artifact tests, pinned
and verified dependencies, checksums, and attestation, not a claim that the build
pipeline is untrusted.

A release may fail after attestations have been created but before the GitHub
release/tag exists.  Such attestations do not create a release tag and do not
change the late-tagging contract.

## Operational Constraints

- The release path MUST execute only from `main`.
- Release validation and publication MUST execute in separate jobs.
- Validation MUST use read-only repository-content permission.
- Validation MUST calculate the version with `create_tag: false`.
- Validation MUST exercise the exact three executable flavors and their checksum
  companions before upload.
- Release validation MUST install Graphviz so SVG/PNG tests do not skip for lack
  of the renderer.
- Publication MUST depend on successful validation.
- Publication MUST NOT rebuild figurectl or synchronize repository dependencies.
- Publication MUST verify the transferred `.sha256` companions before attestation.
- Release/tag creation MUST remain after attestation and checksum verification.
- Inter-job upload/download actions MUST be commit-SHA pinned.
- The transient workflow artifact MUST NOT be described as a seventh public
  release artifact.

## Considered Alternatives

### Keep one broadly privileged release job

This is simpler and preserves the inherited workflow.  It was rejected because
all validation code would continue executing within a job that possesses release
write and OIDC authority even though that authority is needed only at the end.

### Rebuild artifacts in the publication job

This avoids inter-job artifact transport.  It was rejected because publication
would no longer use the exact bytes that passed the validation job and would
require build dependencies to execute with publication authority.

### Allow manual release dispatch from any ref

This is convenient for testing release automation or publishing from maintenance
branches.  It was rejected for the initial release model because it creates a
second source-of-release truth beyond `main` and makes accidental branch
publication easier.  A future maintenance-branch release policy can revisit that
boundary explicitly if a real need appears.

### Create the tag before validation and build from the tag

This gives a convenient immutable-looking input reference.  It remains rejected
by ADR-011 because failed validation could leave a release marker for bytes that
were never approved for publication.

### Use an external artifact repository between jobs

An external service could provide stronger or different retention and signing
semantics.  It was rejected because GitHub Actions already provides bounded
workflow-scoped artifact transport and an external service would add credentials,
network boundaries, and dependencies without a demonstrated requirement.

## Consequences

The release workflow gains one additional job and an explicit upload/download
step.  The workflow is slightly longer, and GitHub Actions artifact storage plus
the pinned upload/download actions become explicit release dependencies.

In return, the larger validation surface runs with substantially less publication
authority, and the publication job becomes small enough to inspect as a distinct
trust boundary.  Maintainers also cannot use manual dispatch from a development
branch as an accidental shortcut around the normal `main` release source.

## Source Lineage

This decision refines the late-tagging and exact-artifact release model inherited
from template-bash and already accepted by figurectl ADR-011.  The motivation also
follows ADR-015's requirement to review build/release dependencies according to
the authority they inherit and ADR-016's requirement to revisit the threat model
when publication privileges change.

## Superseded Decisions

None.

ADR-011 remains in force.  This ADR specifies the least-privilege job boundary used
to implement ADR-011's validation-before-publication sequence.

## Related Decisions

- ADR-003: Make as the Canonical Orchestration Interface
- ADR-005: Dependency Management and Explicit Network Boundaries
- ADR-006: Three Release Artifact Flavors, Metadata, and Checksums
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-011: Conventional-Commit Semantic Releases and Late Tagging
- ADR-012: Standardize SHA-256 Checksum Companion Filenames
- ADR-015: Dependencies as Explicit Attack Surface
- ADR-016: Explicit Threat Modeling for Security-Relevant Changes
