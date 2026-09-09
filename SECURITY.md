# Security Policy

## Scope

`figurectl` is a small open source Bash/AWK tool, not a sandbox or a commercially
supported security product.  It nevertheless processes caller-controlled Markdown,
constructs generated-file paths, optionally invokes Graphviz on caller-controlled
DOT/style data, embeds generated AWK into release artifacts, and uses CI/release
automation with publication authority.  Those boundaries are treated explicitly
rather than hidden behind a broad claim that the tool is "secure."

The project-specific threat model is maintained in `doc/threat-model.md`.
Architecture Decision Records document the decisions behind important runtime,
build, dependency, and release boundaries.

Before the first public release, vulnerability reports may identify the affected
commit.  After releases exist, please identify the exact release and artifact
flavor when practical.

## Reporting a Vulnerability

Please do not disclose a suspected vulnerability in a public GitHub issue before
coordinated disclosure.

Send vulnerability reports to:

[security_vulnerability_disclosure@wesleydean.com](mailto:security_vulnerability_disclosure@wesleydean.com)

Useful reports include:

- affected `figurectl` release or commit;
- artifact flavor when relevant;
- Bash version;
- AWK implementation/version when relevant;
- Graphviz version for graphical-rendering issues;
- operating system or distribution;
- a minimal synthetic reproduction;
- expected behavior and actual behavior;
- relevant stdout, stderr, exit status, or generated files; and
- the security impact and trust boundary you believe is affected.

Please avoid including real production credentials, tokens, private data, or
sensitive unpublished repository content when a synthetic reproducer will
demonstrate the issue.

Good-faith attempts will be made to acknowledge, investigate, and address reports
within a reasonable period.  If communication stalls or a report remains
unresolved, please continue coordinating disclosure through the private contact
above rather than publishing sensitive technical details solely because a fixed
number of days has elapsed.

Once disclosure is appropriate, a public issue, advisory, release note, or other
public record may be created as part of the coordinated resolution.

## Current Security Boundaries

Important current boundaries include:

- figure identifiers are constrained before they become generated filenames;
- built-in input/output plugins are discovered only during build and are embedded
  into standalone artifacts;
- released artifacts do not scan runtime plugin directories or dynamically source
  third-party implementations;
- embedded AWK source is materialized through `mktemp` before `awk -f` execution;
- DOT and style content are passed as data rather than evaluated as Bash source;
- Graphviz is a conditional native-code parser/renderer and is not sandboxed by
  `figurectl`;
- build dependencies are pinned/verified where the project controls their
  acquisition, but pinning does not prove behavioral safety; and
- release validation runs separately from privileged publication so build/test
  code does not intentionally inherit release-write or OIDC authority.

See `doc/threat-model.md`, ADR-015, ADR-016, ADR-018, and ADR-020 for the maintained
analysis and residual risks.

## Non-Promises

The project does not promise:

- safe execution of malicious Graphviz input in a sandbox;
- a third-party runtime plugin trust model;
- protection from a compromised Bash, AWK, Graphviz installation, CI runner,
  GitHub Actions service, or build host;
- atomic replacement of a complete publication directory;
- semantic-equivalence proof between paired text and DOT figures; or
- that checksums, dependency pinning, or attestations prove absence of
  vulnerabilities.

Security-sensitive changes should identify the boundary being protected, the
assets and authority involved, supporting evidence, and residual risk.  Every new
dependency should be treated as an expansion of the trusted computing base.
