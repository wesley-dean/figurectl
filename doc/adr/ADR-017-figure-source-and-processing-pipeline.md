# ADR-017: Figure Source Representation and Processing Pipeline

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This decision migrates the reusable figure-processing architecture originally
established by `wesley-dean/writing` ADR-035 into the standalone `figurectl`
project.  It preserves the observable source notation and select-render-replace
model while separating writing-repository publication policy from reusable tool
behavior.

## Context

The writing repository developed a figure workflow in which a conceptual figure
may have a reader-facing text representation and a Graphviz DOT representation.
Text remains useful in plain Markdown and reflowable workflows, while DOT can
produce publication-quality SVG and PNG output.

An earlier design placed payload inside an HTML comment.  That proved incompatible
with ordinary Markdown when a text diagram contained `-->`, because Markdown/HTML
parsers interpreted that sequence as the end of the comment.  The adopted design
therefore keeps metadata in an HTML comment and payload in an immediately
following native fenced code block.

The writing implementation also established three conceptual phases: select,
render, and replace.  Those responsibilities remain useful outside the writing
repository and define the core behavior of `figurectl`.

## Decision Drivers

- Preserve the known-good writing-repository figure syntax.
- Keep source Markdown readable before processing.
- Keep text and DOT representations near the prose that gives them meaning.
- Let one DOT representation produce both SVG and PNG.
- Keep downstream publication tools unaware of figure directives.
- Preserve narrow, inspectable processing responsibilities.
- Keep reusable figure semantics separate from caller-owned publication styling.
- Maintain compatibility so the writing repository can replace its local script
  with a released `figurectl.bash` artifact.

## Decision

### Source representation

Each authored figure representation SHALL consist of an HTML metadata comment
immediately followed by an ordinary fenced code block containing the payload.

The initial authored source formats SHALL be:

- `text`; and
- `dot`.

Payload SHALL NOT be embedded inside the HTML metadata comment.

The fence information string SHALL agree with the declared source format.  A
mismatch SHALL be an error.

The implementation SHALL support both backtick and tilde fences and SHALL support
fences longer than three characters according to the maintained compatibility
contract.

### Metadata

The initial metadata vocabulary SHALL include `id`, `format`, `alt`, and optional
`caption`.

Stable identifiers and useful alternative text SHOULD be authored explicitly.
Compatibility fallback behavior MAY be retained for missing values, but fallback
metadata is recovery behavior rather than preferred authoring practice.

Identifiers used as generated filenames MUST be validated against a constrained
safe form and MUST NOT permit path traversal or arbitrary pathname injection.

The same identifier MAY occur once for `text` and once for `dot`.  Duplicate
representations with the same identifier and same source format SHALL be rejected.

### Requested output and selected source

The caller SHALL request a publication output format rather than an authored
source format.

The initial mapping SHALL be:

```text
requested output    selected source
----------------    ---------------
text                text
dot                 dot
svg                 dot
png                 dot
```

SVG and PNG SHALL remain derived output formats rather than separately authored
figure source formats.

### Processing phases

`figurectl` SHALL preserve three conceptual processing responsibilities:

1. `select` chooses the authored representation required for the requested output
   and removes non-selected figure representations while preserving unrelated
   Markdown;
2. `render` materializes selected assets and invokes Graphviz when graphical output
   is requested; and
3. `replace` converts the selected figure declaration into ordinary publication
   Markdown.

A public `process` command SHALL perform the complete sequence.

The phases are architectural responsibilities.  They do not require three
separate executables or mandate a particular number of physical parsing passes.

### Rendering relationships

The initial materialization/rendering relationships SHALL be:

```text
text -> .txt
dot  -> .dot
dot  -> Graphviz -> .svg
dot  -> Graphviz -> .png
```

Only assets needed for the requested operation need to be produced.

Graphviz `dot` SHALL be a conditional runtime dependency required only for SVG or
PNG rendering.

### Styling boundary

Reusable `figurectl` behavior SHALL NOT hard-code publication-specific Graphviz
styling.  A caller MAY supply style input through the public interface.  Styling
policy remains caller-owned data.

### Paired representation semantics

Text and DOT representations sharing an identifier SHALL describe the same
conceptual figure.

`figurectl` SHALL NOT claim to prove semantic equivalence between arbitrary text
and DOT.  Semantic-equivalence review remains an author/reviewer obligation.

### Generated assets

Generated text, DOT, SVG, and PNG files SHALL be treated as build products rather
than independent maintained source.

The caller owns generated-directory lifecycle and publication-retention policy
except for files explicitly produced by the requested operation.

## Promises

1. Figure metadata remains separate from payload.
2. Ordinary Markdown outside recognized figure declarations passes through
   unchanged.
3. Requested output remains distinct from authored source format.
4. The select-render-replace responsibilities remain visible and independently
   testable.
5. Downstream publication Markdown does not require figure-directive awareness.
6. Graphical rendering policy can be supplied without becoming hard-coded
   reusable-tool policy.

## Non-Promises

1. The tool does not prove semantic equivalence between paired text and DOT.
2. It does not derive arbitrary DOT from text diagrams.
3. It does not derive compact semantic text diagrams from Graphviz `-Tascii`.
4. It does not promise pixel-identical Graphviz output across versions or fonts.
5. It does not own downstream publication styling or generated-directory pruning
   policy.

## Adversary and Failure Model

Relevant failures include malformed metadata, mismatched fence declarations,
unsafe identifiers, duplicate same-format identifiers, unterminated fences,
missing Graphviz capability, filesystem failures, and payload content that looks
like Markdown or shell syntax but must remain data.

The implementation must fail rather than guess when metadata and payload structure
are inconsistent.  Filename validation must prevent figure identifiers from
escaping the selected output directory.

## Operational Constraints

- Source metadata MUST be followed by a native fenced code block.
- Payload MUST NOT live inside the metadata comment.
- `text` and `dot` MUST be supported authored formats for v1.0.
- `text`, `dot`, `svg`, and `png` MUST be supported requested outputs for v1.0.
- The initial output-to-source mapping MUST remain as documented above.
- `select`, `render`, `replace`, and `process` MUST remain public commands for the
  compatibility baseline.
- Graphviz MUST be required only for graphical rendering.
- Unsafe figure identifiers MUST be rejected.
- Paired representations MUST remain a review obligation rather than a falsely
  automated semantic guarantee.

## Considered Alternatives

### Metadata and payload inside one HTML comment

Rejected because ordinary Markdown/HTML parsing terminates comments at `-->`,
which can legitimately occur inside text diagrams.

### Separate authored SVG and PNG blocks

Rejected because both outputs derive from DOT and duplicated source would create
an unnecessary drift surface.

### DOT as the sole authored representation

Rejected because Graphviz text rendering does not produce the compact semantic
text diagrams used by existing consumers.

### Text as the sole authored representation

Rejected because arbitrary text layout does not explicitly encode graph
relationships needed for reliable graphical rendering.

### Make downstream publication tooling parse figure directives

Rejected because ordinary Markdown is a more composable boundary and keeps
Pandoc, WeasyPrint, ebook tooling, and other consumers independent of custom
figure syntax.

## Consequences

The standalone project inherits a proven syntax and compatibility baseline rather
than inventing a new authoring format during extraction.  Text and DOT remain
independently authored and therefore can drift; that cost is explicit and remains
subject to review.

## Source Lineage

This ADR is adapted from `wesley-dean/writing` ADR-035, "Embed Paired Text and
Graphviz Figure Representations in Manuscripts."  Writing-specific typography,
publisher workflow, and manuscript-governance responsibilities remain in the
writing repository rather than being copied into this reusable tool.

## Superseded Decisions

None within `figurectl`.

The source writing ADR remains historical governance for the writing repository.
A later writing-repository ADR may delegate implementation to released
`figurectl` artifacts without rewriting the original decision history.

## Related Decisions

- ADR-002: Bash Runtime and Portability Baseline
- ADR-009: Observable Behavior Testing Across Shipped Artifacts
- ADR-014: Modularity as Maintenance and Assembly Architecture
- ADR-018: Build-Time Input and Output Plugin Architecture
