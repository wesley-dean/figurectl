# Contributing

Contributions to `figurectl` are welcome.  The project treats public behavior,
architecture, source documentation, tests, generated artifacts, and release
machinery as related parts of one maintained contract, so consequential changes
should keep those surfaces aligned rather than updating only the executable code.

Before consequential work, please read:

- `README.md` for the project purpose and build lifecycle;
- `doc/specification.md` for the public figure-processing contract;
- `doc/engineering-philosophy.md` for reusable engineering posture;
- `doc/decisions.md` and the governing ADRs under `doc/adr/`;
- `AGENTS.md` for the concise repository map;
- `doc/built-in-format-plugins.md` before changing format registration or build
  discovery;
- `doc/documentation-standard.md` before editing maintained Bash comments;
- `doc/awk-documentation-standard.md` before editing maintained AWK source;
- `doc/testing.md` before changing tests or generated artifacts;
- `doc/threat-model.md` when trust, authority, parsing, filesystem, renderer,
  dependency, or release boundaries change; and
- `doc/release-verification.md` before changing release behavior.

## Development Expectations

Prefer focused changes with a clear contract.  Consequential architectural work
should update or add an ADR and the concise decision map.  Public behavior changes
should update `doc/specification.md` before or alongside tests and implementation.

The project follows a documentation-driven, test-second sequence for consequential
work:

1. identify the governing decision and observable contract;
2. update interface/source documentation;
3. add or update focused behavior tests;
4. implement the smallest coherent change;
5. run validation; and
6. review the result against the governing constraints.

Exploration is useful when feasibility is uncertain, but exploratory behavior must
not become an undocumented compatibility commitment merely because code already
exists.

## Validation

The canonical project surfaces are GNU Make targets.  A typical prepared
development environment uses:

```text
make check
make deps-check
make build
make test
make test-report
make docs
```

`make deps` is the explicit network-enabled dependency-convergence boundary.
`make all` performs dependency convergence and then builds.  Build, test,
documentation, and verification targets consume prepared dependency state rather
than silently repairing it.

Generated files under `dist/`, `doc/reference/`, `test-results/`, and `vendor/`
are not maintained source and should not be edited directly.

## Public and Internal Interfaces

The public command surface and Markdown figure syntax are documented in
`doc/specification.md`.  Public commands, options, supported source/output formats,
artifact names, output streams, generated-file behavior, and exit semantics may
be compatibility commitments and should not be changed casually.

Built-in input/output modules under `lib/plugins/` are discovered only during the
build and assembled into standalone artifacts.  They are internal project modules,
not a third-party runtime plugin API.  Runtime directory scanning, dynamic
sourcing, external plugin installation, or arbitrary plugin search paths require a
new architectural decision under ADR-018.

Maintained AWK targets portable AWK.  Maintained Bash targets Bash 4.3 or newer.
Do not raise either portability requirement implicitly.

## Dependencies and Security

A new dependency expands the trusted computing base even when it is used only for
build, testing, documentation, or release.  Review dependency authority, data
exposure, side effects, supply-chain identity, failure behavior, and alternatives
under ADR-015.

Changes to untrusted-input parsing, generated paths, Graphviz execution, build
transformations, dependencies, credentials, workflow permissions, artifact
publication, or similar trust boundaries should update `doc/threat-model.md` when
the current model changes.

Suspected vulnerabilities should be reported according to `SECURITY.md` rather
than in a public issue.

## Pull Requests

Keep pull requests cohesive and reviewable.  A pull request should identify the
problem being solved, governing ADRs/specification sections, material trust or
compatibility implications, and the validation performed.

Generated release artifacts do not need to be committed with a pull request.
Tests and CI build the exact generated representations from maintained source.

## Collaboration Policy

Contributors are expected to follow `CODE_OF_CONDUCT.md`.

## Public Domain

This project is dedicated to the public domain within the United States, and
copyright and related rights in the work worldwide are waived through the
[CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).

See [`LICENSE`](LICENSE) for the repository's license text.  By contributing, you
agree that your contribution will be released under the same CC0 dedication.
