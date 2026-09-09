# figurectl Threat Model

This document applies the review method in [`threat-modeling.md`](threat-modeling.md)
to the current `figurectl` architecture.  It covers the standalone runtime and the
build/release boundaries that materially affect the integrity of published
artifacts.

The model is deliberately bounded.  It records objectives, mitigations, and
residual risk rather than making a general claim that the program, its build
pipeline, or its subprocesses are secure.

## Scope and Security Objectives

The current review covers:

- deterministic build-time discovery of maintained input/output plugins;
- assembly of modular Bash and AWK source into standalone Bash artifacts;
- comment stripping and Bash minification;
- runtime materialization of trusted embedded AWK source;
- Markdown figure parsing and identifier validation;
- generated-file paths beneath caller-selected figure directories;
- conditional Graphviz execution for SVG/PNG rendering;
- release validation of exact generated artifacts;
- transfer of validated release files between GitHub Actions jobs; and
- separation of read-only validation authority from privileged attestation and
  release publication.

The primary security and integrity objectives are:

1. released artifacts execute only the built-in implementations assembled during
   the reviewed build;
2. runtime behavior does not depend on plugin directories, `src/`, `lib/`, or
   `vendor/`;
3. malformed figure identifiers do not become path traversal outside the
   caller-selected figure directory;
4. comment stripping and minification do not silently alter the embedded AWK
   program's observable behavior;
5. generated AWK temporary files are created without predictable shared
   filenames and are removed after use where practical;
6. ordinary data output and diagnostics retain their documented stdout/stderr
   separation;
7. repository build/test/dependency code does not receive publication authority
   merely because it participates in release validation; and
8. the bytes published in a GitHub release are the same six files that passed
   validation and checksum verification before crossing into the publication job.

## Assets

Assets relevant to these objectives include:

- maintained Bash, AWK, and plugin source;
- the selected set and ordering of built-in implementations;
- generated `figurectl.dev.bash`, `figurectl.bash`, and `figurectl.min.bash`
  artifact bytes;
- checksum companions and release attestations;
- Git tags and GitHub release records;
- the transient GitHub Actions artifact carrying validated release files between
  jobs;
- GitHub Actions publication authority and OIDC token-minting capability;
- the caller's Markdown input;
- the caller-selected figures directory and files adjacent to it;
- caller-supplied Graphviz style content;
- generated text, DOT, SVG, and PNG assets; and
- downstream trust in the documented public behavior contract.

## Trusted Computing Base

The current trusted computing base includes:

- reviewed `figurectl` maintained source;
- Bash 4.3 or newer;
- the selected portable AWK implementation;
- standard filesystem utilities used by the orchestrator, including `mktemp`,
  `mkdir`, and `rm`;
- GNU Make and the maintained build recipes during artifact production;
- the pinned Bash-Minifier dependency when producing the minified artifact;
- bashdeps and other prepared build/release dependencies within their documented
  authority;
- Graphviz `dot` when graphical rendering is requested or release behavior is
  validated;
- pinned GitHub Actions used to calculate versions, upload/download validated
  workflow artifacts, create attestations, and publish releases;
- GitHub-hosted runner behavior and GitHub Actions artifact storage; and
- GitHub's attestation, tag, and release services.

Graphviz is not trusted for shell interpretation because DOT/style text is never
constructed as shell source.  It is nevertheless trusted as native code parsing
caller-controlled graph input with the authority of the `figurectl` process or
release-validation job.

The validation job and publication job deliberately have different authority.
Validation code remains part of the trusted build surface because it determines
the bytes that are approved, but it does not need repository-content write,
attestation write, artifact-metadata write, or OIDC publication authority.

## Trust Boundaries

The principal runtime and release boundaries are:

```text
maintained source
      |
      v
Make discovery and deterministic assembly
      |
      v
generated Bash artifact
      |
      +--------------------------+
      |                          |
      v                          v
embedded trusted AWK       built-in registry
      |                          |
      +------------+-------------+
                   v
             AWK processor
                   |
          validated figure id
                   |
                   v
          generated source asset
                   |
             optional Graphviz
                   |
                   v
          SVG / PNG build asset
```

```text
main commit
    |
    v
read-only release validation
    |
    | exact six files + checksums
    v
transient GitHub Actions artifact
    |
    v
privileged publication job
    |
    +--> checksum verification
    +--> attestations
    +--> Git tag / GitHub release
```

Caller-controlled Markdown crosses into the AWK parser.  Caller-controlled
`--figures-dir`, `--link-prefix`, and `--dot-style` values cross into filesystem or
rendering behavior.  Maintained source crosses a supply/build boundary before it
becomes an executable consumer artifact.  Validated release bytes cross a second
boundary from the larger read-only validation surface into the narrowly privileged
publication job.

## Threats, Mitigations, and Residual Risk

### Runtime plugin injection

**Threat:** local filesystem state, environment variables, or attacker-created
plugin files alter which implementation executes after release.

**Mitigations:** plugin paths are discovered only by the build; the resulting
source is concatenated into the artifact; there is no runtime plugin search path,
directory scan, dynamic `source`, or third-party loading option.  Artifact tests
execute after removing access to maintained source/dependency trees.

**Residual risk:** a compromised artifact or compromised build can still contain
malicious built-in code.  Standalone distribution removes runtime discovery risk;
it does not make the build supply chain irrelevant.

### Nondeterministic or hidden plugin assembly

**Threat:** peer plugin ordering or filesystem enumeration causes different
artifacts to contain different implementations unexpectedly.

**Mitigations:** Make performs lexical discovery for additive input/output modules,
while semantically ordered core source remains explicit.  Plugin registration
rejects duplicate logical names.  Repeated builds with identical source and build
metadata are compared byte-for-byte in CI.

**Residual risk:** a reviewed change adding a new built-in plugin intentionally
changes artifact behavior.  Public format support therefore remains documented
and tested rather than inferred from directory contents alone.

### Embedded-AWK delimiter collision

**Threat:** maintained AWK source contains the build's heredoc terminator as a
standalone line, truncating or corrupting generated Bash syntax.

**Mitigations:** the build uses project-specific literal heredoc sentinels and
fails before assembly if either sentinel appears as an exact line in the AWK
source being embedded.  Generated artifacts also receive Bash syntax validation
and behavior tests.

**Residual risk:** build logic itself remains trusted.  A future change to the
embedding representation must receive equivalent collision analysis.

### Comment stripping changes embedded AWK

**Threat:** the ordinary-artifact transform removes a line beginning with `#`
inside the embedded AWK heredoc and accidentally removes executable data rather
than documentation/comments.

**Mitigations:** maintained embedded AWK uses full-line `#`/`##` only for AWK
comments and documentation.  The same behavior suite executes against the
fully-documented and comment-stripped artifacts, so semantic divergence becomes a
test failure rather than an assumption.

**Residual risk:** future AWK code that intentionally requires a literal
full-line string beginning with `#` in the heredoc representation could invalidate
this assumption.  Such a change must update the build transformation or its
representation before merge.

### Bash-Minifier changes heredoc behavior

**Threat:** minification rewrites Bash surrounding the AWK heredoc or alters
literal heredoc bytes so the minified program parses or behaves differently.

**Mitigations:** minification occurs only after complete artifact assembly, and
the full public behavior contract is run against the exact minified artifact.
Tests include payloads and embedded program text containing shell-looking and
Markdown-sensitive characters.

**Residual risk:** behavior tests cannot prove equivalence for every possible
input.  The minifier remains part of the trusted build dependency surface under
ADR-015.

### Predictable temporary AWK program path

**Threat:** a shared predictable temporary pathname allows another process to
replace or observe the embedded program before AWK executes it.

**Mitigations:** the orchestrator creates temporary AWK files with `mktemp`, writes
only trusted embedded source into the returned path, executes AWK with `-f`, and
removes the file after the invocation while preserving the AWK exit status.

**Residual risk:** the operating system's temporary-directory permissions,
`mktemp` implementation, local same-user processes, and filesystem semantics are
outside `figurectl`'s direct control.  The embedded AWK source is not confidential;
the objective is integrity and predictable execution.

### Figure identifier path traversal

**Threat:** a caller supplies an identifier such as `../escape`, an absolute path,
or a separator-bearing name that causes materialization outside
`--figures-dir`.

**Mitigations:** metadata validation accepts only identifiers matching
`[A-Za-z0-9][A-Za-z0-9._-]*` before an identifier is used to construct an asset
pathname.  Negative tests verify rejection and absence of an escaped output file.

**Residual risk:** the caller chooses `--figures-dir` itself and therefore owns the
scope of the directory into which valid figure filenames are written.  Existing
files with valid generated names may be replaced; atomic directory publication is
not promised by the specification.

### Caller-controlled link prefix

**Threat:** `--link-prefix` is confused with a filesystem path and causes writes
outside the intended output directory.

**Mitigations:** the link prefix participates only in emitted Markdown image
references.  Materialized and rendered files continue to use `--figures-dir`.

**Residual risk:** downstream Markdown consumers may interpret unusual link text
according to their own rules.  figurectl does not claim to sanitize arbitrary
Markdown URLs beyond the established compatibility behavior.

### Caller-controlled DOT and style content

**Threat:** untrusted DOT or style text exploits Graphviz behavior, consumes
excessive resources, or produces unexpected graph output.

**Mitigations:** Graphviz is invoked directly with an argument vector; DOT/style
content is not evaluated by Bash.  Graphviz is required only for SVG/PNG output,
and rendering failure is surfaced rather than silently ignored.  Release
validation installs Graphviz so graphical public behavior executes rather than
being silently skipped because the renderer is unavailable.

**Residual risk:** Graphviz remains a native-code parser and renderer receiving
caller-controlled content.  figurectl does not sandbox Graphviz, impose graph-size
limits, or promise protection from vulnerabilities or resource-exhaustion behavior
inside the installed Graphviz version.

### Validation code inherits publication authority

**Threat:** repository-controlled source, synchronized dependencies, build tools,
renderers, or test code execute in a job that also possesses repository write,
attestation, or OIDC authority, allowing compromise of the validation surface to
reach publication mechanisms directly.

**Mitigations:** ADR-020 separates release validation from publication.  The
validation job has read-only repository-content permission while it calculates the
version without tagging, prepares dependencies, builds, tests, runs Graphviz,
checks Bash 4.3 compatibility, and verifies the exact release set.  Only the later
publication job receives the permissions needed for attestation and release/tag
creation, and that job does not check out or execute project build/dependency code.

**Residual risk:** validation code still determines which bytes are approved and
uploaded.  A compromised build dependency can therefore influence the candidate
artifacts even without direct publication credentials.  The mitigation reduces
authority and blast radius; it does not make the build pipeline untrusted.

### Inter-job release artifact transport

**Threat:** release files are missing, substituted, or altered between validation
and publication, or publication independently rebuilds bytes that never passed the
validation suite.

**Mitigations:** validation uploads exactly the three executables and their three
`.sha256` companions as one named workflow artifact.  Publication downloads that
artifact without rebuilding, verifies the exact six-file inventory, and runs
`sha256sum -c` after transport before attestation.  Upload/download actions are
pinned by commit SHA.

**Residual risk:** GitHub Actions artifact storage, GitHub-hosted runners, and the
pinned upload/download action implementations remain trusted release
infrastructure.  The per-artifact checksums establish consistency with the
sidecars produced during validation; they are not an independently rooted
signature.

### Premature release tag creation

**Threat:** a semantic-version tag exists even though build, tests, checksum
verification, transfer, or attestation later fails.

**Mitigations:** semantic version calculation uses `create_tag: false`.  The
release/tag action is the last publication step after validation, inter-job
checksum verification, and attestation.  The release workflow is restricted to the
`main` ref for both automatic and manually dispatched release execution.

**Residual risk:** release creation itself can fail after attestations have been
created.  Such a failure may leave attestation records associated with validated
files, but it does not create the release tag early.

## Explicit Non-Goals

The current design does not attempt to provide:

- a sandbox for malicious Markdown, DOT, or Graphviz style input;
- a third-party plugin trust or permission model;
- cryptographic verification of maintained source during local development;
- atomic replacement of the caller's complete publication directory;
- protection from a compromised Bash, AWK, Graphviz, CI runner, GitHub Actions
  service, or build host;
- semantic equivalence proof between text and DOT representations;
- confidentiality for the embedded AWK implementation; or
- an independently reproduced release build from a second trust domain.

## Security Evidence

Current evidence for this model includes:

- accepted ADR constraints for build-time-only plugins and standalone artifacts;
- focused metadata/path-validation tests;
- the same Bats public behavior suite against all artifact flavors;
- Bash syntax validation of generated artifacts;
- minimum-Bash compatibility execution;
- deterministic-build comparison;
- SHA-256 artifact companions;
- Graphviz-present release validation for graphical outputs;
- isolated-runtime tests that remove maintained source and `vendor/` before
  exercising the generated program;
- separate read-only validation and privileged publication jobs;
- exact six-file verification before and after inter-job transport; and
- attestation sequencing before late release/tag creation.

## Review Triggers

Revisit this threat model when a change adds or alters:

- runtime/external plugin loading;
- the set of trusted renderers;
- identifier or pathname grammar;
- filesystem write/delete behavior;
- the AWK embedding representation;
- comment stripping or minification;
- dependency acquisition or pinning;
- network access;
- privilege or credential use;
- release job permissions, artifact transport, attestation, or publication
  sequencing; or
- the Bash/AWK runtime compatibility floor.
