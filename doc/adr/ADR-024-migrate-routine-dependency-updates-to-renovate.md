# ADR-024: Migrate Routine Dependency Updates to Centrally Managed Renovate

Date: 2026-11-26

## Status

Accepted

## Decision

The repository SHALL enroll in the existing centrally managed Jenkins Renovate
service using a minimal root `renovate.json`. The active Dependabot GitHub
Actions version-update ecosystem SHALL set `open-pull-requests-limit: 0`
while preserving its other settings, in order to stop scheduled routine
Dependabot PR creation. Dependabot security alerts and security updates
remain independent. The existing `dependabot[bot]`-scoped non-major
auto-merge logic remains restricted to Dependabot security PRs.

This ADR partially supersedes ADR-023 with respect to its selection of
scheduled Dependabot as the routine update provider, its requirement to
retain weekly routine grouping as an active policy, and its objection to a
zero routine PR limit. ADR-023's security response, supply-chain review,
release-path validation, and mandatory review constraints remain applicable.
Historical text is retained as an audit trail.

## Context and Constraints

The maintainer has configured a centrally operated Jenkins Renovate job
for `wesley-dean/*`. Independent scheduled Dependabot update PRs would
duplicate that workflow. Explicit repository enrollment is necessary, while
Renovate scheduling, credentials, and signing remain centrally managed.

figurectl distributes Bash/AWK tooling, generates reference documentation,
runs tests against release formats, and separates release validation from
publication authority under ADR-020. This maintenance migration SHALL NOT
alter runtime interfaces, source extraction, artifacts, dependency manifests,
release permissions, or trusted build boundaries.

## Assumptions

- The central Jenkins job discovers this repository and requires the root
  Renovate enrollment file.
- The maintainer will provision `wesley-dean-renovate` access when approving
  the migration PR.
- Required checks, CODEOWNERS approval, and GitHub protections govern
  native auto-merge, independently of bot configuration.
- GitHub security-update settings are administered independently of this YAML.
- Successful configuration merge is not evidence of successful Jenkins
  execution or subsequent pinning.

## Alternatives Considered

1. **Continue scheduled Dependabot versions.** Rejected as redundant with
   centralized maintenance.
2. **Delete Dependabot YAML.** Rejected to preserve ecosystem context and
   security-update separation.
3. **Run Renovate as a repository-specific GitHub Action.** Rejected because
   this would duplicate central credentials, scheduling, and operations.
4. **Extend the Dependabot auto-merge workflow to Renovate.** Rejected because
   bot identity and the code-owner review boundary must remain distinct.
5. **Convert all action SHA pins to floating tags.** Rejected: independently
   verified SHA pins remain the preferred immutable reference.

## Migration and Consequences

The PR adds root Renovate enrollment, disables scheduled Dependabot version
PRs, and updates repository maintenance documentation. GitHub Actions
`# pin@` comments are normalized only where tag-to-commit mappings are
verified from upstream. An unverified SHA may be temporarily replaced with a
valid `@version` reference without its stale pin annotation, explicitly
documenting the weaker provenance boundary until a reviewed Renovate PR
restores an immutable pin.

Once the migration PR exists, conclusively routine Dependabot PRs may be
closed with a link to that migration; security-related, ambiguous, or
human-modified PRs remain open. No assumption is made that Renovate has already
processed the repository or generated a replacement update.

## Risks and Tradeoffs

Centralizing dependency updates introduces reliance on one Jenkins runner and
machine-account PR-writing credentials. Any temporary floating action ref
increases upstream substitution risk; changes to signing, tag creation,
release artifact publication, and CI write permissions require targeted
review and must preserve ADR-015, ADR-016, and ADR-020 constraints. Required
checks, human approval, and immutable action pins should be maintained.
This migration does not grant automatic approval or bypass review protection.

## Related Decisions

- ADR-015 and ADR-016: Dependency trust and threat modeling.
- ADR-020: Separation of release validation from publication authority.
- ADR-022: Shared coding standards and provenance.
- ADR-023: Historical Dependabot grouping policy, partially superseded here.
