<!-- Keep the title brief and useful as a changelog entry. -->
<!-- Link a relevant issue when one exists. -->
<!-- markdownlint-disable -->

Fixes #

<!-- markdownlint-restore -->

## Summary

<!-- What figurectl problem does this change address, and what behavior changes? -->

## Architectural impact

<!--
Identify governing ADRs or explain why no architectural decision changes.  If the
change establishes a durable new decision, add or update an ADR and the concise
decision map.  Public behavior changes should also update doc/specification.md.
-->

## Security / trust impact

<!--
Does this change dependencies, authority, untrusted-input handling,
network/filesystem access, Graphviz or other subprocesses, plugin boundaries,
build transformations, CI/release authority, or security claims?  If so, summarize
the threat-model impact and residual risk.
-->

## Validation

<!-- List the checks/tests relevant to this change. -->

- [ ] `make check`
- [ ] `make test`
- [ ] `make docs`
- [ ] `make deps-check` when dependency state or acquisition changed
- [ ] `doc/release-verification.md` reviewed when release behavior changed

## Readiness checklist

- [ ] Public commands, options, formats, outputs, artifacts, or Make targets are
      documented when affected.
- [ ] Governing ADRs and `doc/decisions.md` are updated when architecture changed.
- [ ] Promises and non-promises are explicit for consequential new behavior.
- [ ] Bash Doxygen comments follow `doc/documentation-standard.md` when maintained
      Bash contracts changed.
- [ ] AWK documentation follows `doc/awk-documentation-standard.md` when maintained
      AWK contracts changed.
- [ ] Tests exercise each affected shipped artifact flavor.
- [ ] Negative assertions are included when the contract requires forbidden data
      or behavior to remain absent.
- [ ] New dependencies were reviewed as additions to the trusted computing base.
- [ ] `doc/threat-model.md` was reviewed when trust, authority, parsing,
      filesystem, renderer, dependency, or release boundaries changed.
- [ ] Build-time plugin changes preserve the no-runtime-plugin boundary unless a
      new ADR explicitly changes it.
- [ ] Repository-facing documentation/templates contain no stale project names,
      unrelated links, or inherited policies that no longer apply.

### Reviewing maintainer

- [ ] Label as `breaking` if this is a large fundamental change.
- [ ] Label as `automation`, `bug`, `documentation`, `enhancement`,
      `infrastructure`, or `performance` as appropriate.
