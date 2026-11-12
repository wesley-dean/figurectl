# ADR-023: Consolidate GitHub Actions Dependabot Version Updates

Date: 2026-11-12

## Status

Accepted

## Decision

Retain the repository's weekly GitHub Actions Dependabot version-update
schedule and seven-day cooldown. Replace the `minor-and-patch` group with one
broad `actions-version-updates` group whose explicit
`applies-to: version-updates` and `patterns: ["*"]` include eligible major,
minor, and patch dependency version changes.

Security updates remain outside routine version-update grouping and must not
wait for the weekly schedule or cooldown. A group containing a major update
is not eligible for the existing non-major-only auto-merge workflow, and
must be reviewed for its highest-risk change. The current GitHub Actions
permissions, required-check identities, review protections, and auto-merge
conditions are not changed by this decision.

## Context

The previous weekly configuration grouped only minor and patch version
updates. Major updates generated separate routine PRs, raising the
maintainer's workload. The verified `coding_standards@v3.2.0` snapshot
recommends a balanced, per-ecosystem wildcard version-update group with a
seven-day cooldown. Consolidating eligible updates reduces fragmentation but
may combine a breaking major upgrade with otherwise safe changes.

figurectl has a Bash runtime with embedded AWK, tested release flavors,
documentation generation, optional Graphviz execution, and separate
release-validation and publication boundaries. GitHub Actions dependencies
can affect these boundaries and must be inspected deliberately.

## Constraints and Assumptions

- The only configured Dependabot ecosystem is `github-actions`.
- The weekly cadence, seven-day cooldown, and commit conventions remain.
- `dependabot/fetch-metadata` currently gates auto-merge on the highest
  update type being different from `version-update:semver-major`; retain it.
- Reviewers must inspect changes to privileged build, CI, and publishing
  actions; a passing linter alone is insufficient evidence.
- GitHub security-update settings, branch rulesets, and effective CODEOWNERS
  reviews cannot be inferred from YAML and require separate verification.
- ADR-020 continues to separate release validation from publication power.
  No additional token permissions, artifact publication authority, or
  generated release contract change is approved.

## Alternatives Considered

1. **Retain minor/patch-only grouping.** Rejected as the baseline because it
   creates separate major-version PRs without improving their required scrutiny.
2. **Group major, minor, and patch routine version updates.** Selected with
   explicit manual review for groups that include major changes.
3. **Move to monthly updates or longer cooldowns.** Rejected without evidence
   that slower visibility is safe or advantageous for this active project.
4. **Auto-merge major-containing groups.** Rejected because breaking changes,
   runtime/CI provenance, and release authority demand independent inspection.
5. **Close existing update PRs immediately.** Rejected because the new grouping
   does not prove that old updates are replaced or tested.

## Consequences, Risks, and Verification

Routine version-update volume may decline, but resolution failures or
incompatible dependency upgrades can still produce multiple PRs. Group
failures can be harder to diagnose; isolate problematic updates where
warranted by evidence and local policy. Do not treat security updates as
routine version updates, and do not add `ignore` directives merely to hide
dependencies.

Review any grouped major change against release notes, migration behavior,
permissions, trust boundaries, and tests exercising figurectl's affected
Bash/AWK and release workflows. Verify that the actual Dependabot metadata
and non-major-only auto-merge condition exclude groups containing a major
upgrade. Preserve existing Dependabot PR #15 until any replacement is proven
equivalent and appropriately tested.

This decision makes no source, CLI, artifact, build, runtime, or release
permission change. It does not establish GitHub-side protection settings.

## Related Decisions

ADR-022 governs immutable shared standards and provenance; ADR-011 governs
release semantics. ADR-015 and ADR-016 cover dependency security and
threat modeling. ADR-020 keeps validation and release publication separate.
This decision supplements, and does not supersede, those constraints.
