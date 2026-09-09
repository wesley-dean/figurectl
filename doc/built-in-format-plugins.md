# Built-In Format Plugin Contract

This document defines the maintained-source contract used by `figurectl` for
built-in authored-source and requested-output implementations.

The governing architectural decision is ADR-018.  This document describes the
implementation shape chosen for that decision; it does not create a third-party
plugin API or a runtime extension mechanism.

## Scope

`figurectl` distinguishes two kinds of built-in format modules:

- **input/source plugins**, which describe authored figure representations; and
- **output plugins**, which describe requested publication formats.

Plugin source is discovered deterministically by `make build`, assembled into the
standalone Bash artifacts, and then becomes ordinary trusted program code.  The
released executable never scans a plugin directory, sources files from a runtime
search path, or attempts to discover additional implementations after build.

The v1.0 built-in source formats are `text` and `dot`.  The v1.0 requested output
formats are `text`, `dot`, `svg`, and `png`.

## Source Layout

The maintained plugin locations are:

```text
lib/plugins/input/*.bash
lib/plugins/output/*.bash
```

Input and output files are additive leaf modules.  Their paths are discovered in
lexical order by the build.  Peer ordering must not encode implementation
dependencies; any dependency significant enough to affect correctness belongs in
explicitly ordered core source.

Maintained plugin filenames must remain whitespace-free so Make can keep discovery
and provenance inspectable without introducing a second path-encoding mechanism.

## Registration Model

Each input plugin registers one authored representation through the internal
format registry.  The input contract contains:

```text
logical source name
materialized source extension
```

For example, the built-in text implementation registers `text` with the `txt`
materialized extension, while DOT registers `dot` with the `dot` extension.

Each output plugin registers one requested publication format.  The output
contract contains:

```text
logical output name
required authored source
replacement kind
output extension
renderer function, when required
fenced-block information string, when required
```

The initial replacement kinds are:

- `fence` for outputs represented as a fenced code block; and
- `image` for outputs represented as a Markdown image reference.

A renderer function is empty for outputs that require no transformation beyond
source materialization.  SVG and PNG register the shared Graphviz renderer.

The registry validates duplicate names and malformed registrations while the
assembled artifact initializes.  Registration state exists only inside the
already-built program; it is not filesystem discovery.

## Capability-Oriented Dispatch

Core orchestration asks the registry for capabilities instead of maintaining
format-specific dispatch branches throughout the program.

The registry provides enough information to answer questions such as:

- Is a requested output supported by this artifact?
- Which authored source does that output require?
- Which extension is used when the source payload is materialized?
- Is replacement a fenced block or a Markdown image?
- Which renderer function, if any, converts the materialized source?

The portable AWK processor receives the registered source-format inventory and
selected output capabilities as data.  It does not scan plugin files and does not
need a format-specific filesystem layout at runtime.

## AWK Boundary

The figure parser remains explicitly ordered portable-AWK core source under
`lib/awk/`.  Those modules own Markdown parsing, metadata validation, fence
recognition, figure-state transitions, materialization, and replacement.

`make build` concatenates the ordered AWK core into literal quoted heredocs inside
the generated Bash artifact.  At runtime, the orchestrator materializes that
trusted embedded program to a secure temporary file and invokes AWK with `-f`.
The generated executable therefore retains the same multi-file maintenance model
without requiring those files after installation.

The AWK processor is parameterized from the built-in registry.  In particular,
supported source formats and materialized extensions are no longer hard-coded in
the parser, and replacement behavior receives the selected output's kind,
extension, and fenced information string from the registry.

## Build-Time Discovery Boundary

The build is the only component that discovers plugin source paths.

The generated artifact contains:

1. explicitly ordered Bash core modules;
2. deterministically discovered input plugin modules;
3. deterministically discovered output plugin modules;
4. embedded ordered AWK processor source;
5. embedded DOT-style AWK source; and
6. the figurectl orchestrator/entry point.

Build provenance records which plugin paths were discovered and assembled.

No runtime environment variable, option, directory, configuration file, or
filesystem location may add another plugin implementation in v1.0.

## Failure Semantics

A malformed or duplicate maintained registration is a build/product defect and
must fail conservatively when the assembled program initializes.  A requested
output that is not registered in the built artifact is ordinary invalid CLI usage
and follows the public unsupported-format behavior.

A registered output that names an unavailable renderer function is an internal
artifact defect and must fail rather than fall back to external discovery.

## Testing Contract

The behavior suite must run against the exact development, ordinary, and minified
artifacts.  Tests must prove that all v1.0 formats survive:

- build-time module discovery;
- Bash source assembly;
- AWK heredoc embedding;
- full-line comment stripping; and
- Bash-Minifier transformation.

Tests must also prove that a built artifact can execute away from the maintained
`src/`, `lib/`, and `vendor/` trees.  This is executable evidence that discovery
and dependency preparation ended before runtime.

## Non-Promises

This contract does not promise:

- runtime plugin discovery;
- third-party plugin installation;
- dynamic sourcing or hot loading;
- a stable external plugin ABI/API;
- renderer discovery from the filesystem; or
- compatibility for arbitrary plugin modules not maintained by the project.

Adding any of those capabilities requires a new architectural decision under
ADR-018.
