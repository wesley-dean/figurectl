# AWK Documentation Standard

This document defines the normative source-documentation standard for maintained
AWK files in projects that adopt it.  The standard deliberately prefers verbose,
explanatory documentation.  Source brevity is not a goal when brevity would
force a future maintainer to infer intent, contracts, assumptions, failure
semantics, state ownership, portability constraints, security boundaries, or
architectural relationships from executable code alone.

This standard is modeled after the documentation approach used for maintained
Bash projects and is intentionally compatible with the `awk-doxygen` tooling
model.  The syntax and structure described here are requirements, not examples
of a general style that may be replaced with something merely similar.

AWK has a substantially different execution model from Bash.  Functions have
real return values rather than shell-style exit statuses, variables are created
through use rather than declarations, function-local variables are commonly
represented by omitted formal parameters, and much program behavior lives in
`BEGIN`, `END`, and pattern/action rules rather than named functions.  This
standard therefore preserves the documentation philosophy of the Bash model
while defining AWK-specific contracts rather than mechanically copying Bash
semantics.

Maintainers should not reduce source documentation merely to optimize release
size.  If a project produces stripped, generated, or minified consumer
artifacts, that distribution policy is separate from the maintained
source-documentation standard.  Prefer thorough, detailed, in-depth commentary
over brevity.  The goal is for the work to be accessible, readable, and
maintainable while targeting developers with basic AWK competence.

Pay particular attention to assumptions and preconditions.  Consider that the
reader may be a human new to the project or an AI/LLM operating with focused
context that may not retain the complete project history or the consequences of
prior decisions.

## Language and Portability Floor

Unless governing project documentation states otherwise, maintained AWK source
covered by this standard should be documented as portable AWK rather than as a
specific implementation such as GNU awk, mawk, or BusyBox awk.

When source depends on implementation-specific behavior or extensions, the
relevant documentation must identify that dependency explicitly.  Do not
describe code as portable AWK when correctness actually depends on an
implementation-specific feature.

Examples of portability-sensitive concerns include:

* implementation-specific built-in variables or functions;
* implementation-specific regular-expression behavior;
* implementation-specific command-line options;
* implementation-specific array behavior;
* implementation-specific namespace or indirect-call features;
* multibyte and locale behavior;
* non-portable uses of `getline`, redirection, or process control; and
* assumptions about which `awk` implementation `/usr/bin/awk` or the user's
  `PATH` selects.

Portability claims are part of the interface contract and must be documented
with the same care as input and output behavior.

## Comment Syntax

Doxygen documentation lines begin with exactly two hash characters:

```awk
## @file lib/example.awk
## @brief Provides an example capability.
## @details
## This module exists to preserve a specific contract.  The details explain why
## the capability belongs here, how callers should use it, and what assumptions
## future changes must preserve.
```

Use ordinary single-hash comments for narrow implementation annotations that are
not intended to become part of generated reference documentation.  Prefer
Doxygen comments whenever the material helps explain an interface, invariant,
module responsibility, non-obvious decision, maintenance constraint, portability
assumption, data-shape contract, state transition, or security boundary.

The project does not use another Doxygen comment dialect in maintained AWK
source.  Do not replace these blocks with `#**`, `##<`, or another convention
without an architectural decision that explicitly changes the `awk-doxygen`
integration.

Lines in documentation commentary should be limited to 80 characters or less,
except for unbreakable content such as long URLs or literal values whose form is
part of the contract.

## Relationship to awk-doxygen

`awk-doxygen` is the designated Doxygen filter for projects adopting this
standard.  It converts intentionally documented AWK constructs into a
Doxygen-friendly intermediate representation.  The generated representation is
an indexing target for Doxygen; it is not intended to be compiled or executed.

The tooling model is documentation-led rather than parser-led.  The filter
should recognize only the subset of AWK structure required to associate explicit
Doxygen blocks with functions, documented variables, `BEGIN`/`END` blocks, and
pattern/action rules.  It must not claim to be a complete AWK parser.

The structural vocabulary defined by this standard includes:

* `@file` for file-level documentation;
* `@fn` for named AWK functions;
* `@param` for caller-supplied function parameters;
* `@local` for conventional omitted formals used as function-local storage;
* `@var` for significant documented global variables or arrays; and
* `@rule` for named documentation identities assigned to AWK rules, including
  `BEGIN`, `END`, and ordinary pattern/action rules.

Ordinary Doxygen commands such as `@brief`, `@details`, `@returns`, `@retval`,
`@note`, `@warning`, `@see`, `@par`, `@code`, and `@endcode` retain their normal
role unless this standard defines a more specific AWK interpretation.

`@local` and `@rule` are AWK-source structural directives.  They exist so the
filter can preserve AWK semantics without pretending that conventional locals
are ordinary public parameters or that anonymous rules are named source-level
functions.  The generated Doxygen representation may suppress or translate these
directives as necessary.

When `@fn`, `@var`, or `@rule` is used, the documented identity must agree with
the construct being documented according to the validation rules established by
`awk-doxygen`.  Documentation identity is part of the maintained-source contract,
not decorative prose.

Where practical, the filter should preserve source line correspondence so that
Doxygen diagnostics and generated references remain close to the original AWK
locations.  Tooling should favor one-for-one line translation over expanding
short source blocks into substantially longer generated structures.

## File Blocks

Every maintained AWK source file must contain a file-level Doxygen block near the
start of the file:

```awk
## @file lib/redaction.awk
## @brief Provides the core redaction pipeline.
## @details
## Explain the module's responsibility, state ownership, security boundary,
## interactions with record processing, and assumptions future changes must
## preserve.
```

If the file is directly executable and governing project policy requires a
shebang, the shebang may precede the Doxygen block:

```awk
#!/usr/bin/awk -f
## @file bin/example.awk
## @brief Processes example input records.
## @details
## Explain why the program exists, the expected record stream, output contract,
## and portability assumptions.
```

A shebang is not required merely because a file contains AWK.  Source intended
to be invoked with `awk -f file.awk` may begin directly with the Doxygen file
block.  The project must not invent a shebang requirement in the documentation
standard when execution policy belongs elsewhere.

The file details must explain the module's responsibility, its relationship to
neighboring modules or invoking shell code, important global state it owns,
record-processing assumptions, and constraints that affect safe modification.
A useful file block answers "why does this AWK program or module exist?" as well
as "what functions and rules does it contain?"

When applicable, the file block should identify:

* the expected input-record model;
* assumptions about `FS`, `RS`, `OFS`, `ORS`, or other built-in variables;
* whether input is expected on standard input, named files, or both;
* whether `ARGV` is inspected or modified;
* whether `ENVIRON` participates in configuration;
* whether output is intended for another machine-readable stage;
* whether output ordering is significant;
* whether global arrays or counters carry state across records;
* whether `BEGIN` or `END` establishes or finalizes important invariants;
* whether the program executes subprocesses or writes files; and
* which AWK implementation or portability floor is required.

Security-sensitive modules must explicitly identify the boundary they enforce
and link to governing ADRs when that context materially improves review.

## Function Blocks

All maintained AWK functions must use the following vocabulary as applicable:

```awk
## @fn example_lookup(name)
## @brief Looks up a named example.
## @details
## Explain the contract, assumptions, side effects, global state interaction,
## and why the function exists.  Describe non-obvious behavior and interactions
## with other functions or rules.
##
## @param name Logical name to look up.
## @local value Scratch value used while resolving the lookup.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A diagnostic may be written when the request is invalid.
##
## @returns The matching string, or the empty string when no match exists.
##
## @par Examples
## @code
## value = example_lookup("demo")
## @endcode
function example_lookup(name,    value) {
    # implementation
}
```

Document caller-supplied parameters in declaration order.  Document conventional
locals in declaration order after the public parameters.  Document direct reads
from standard input, direct writes to standard output, and direct writes to
standard error.  Document the function's AWK return value independently from
stream side effects.

Examples are strongly preferred for public, parsing, transformation, validation,
normalization, redaction, formatting, emission, stateful, or otherwise
non-trivial interfaces.  Examples should demonstrate intended use, not
manufacture a second test suite inside comments.

For security-sensitive functions, `@details` must explain important
preconditions, failure behavior, ordering assumptions, input-trust assumptions,
and what the function must never emit, execute, interpret, or expose.

Material side effects must be documented in `@details` or, when useful, in a
dedicated `@par Side Effects` section.  This includes modification of global
variables or arrays, mutation of array parameters, changes to AWK built-in
variables, file creation or writes, subprocess execution, changes to `ARGV`, or
other state visible outside the function's local working variables.

### Function Parameters

AWK function parameter lists combine two conceptually different kinds of names:
caller-supplied arguments and conventional pseudo-local variables.

For example:

```awk
function parse_record(line, separator,    fields, count) {
```

AWK itself treats all four names as formal parameters.  By longstanding
convention, `fields` and `count` are omitted by callers and used as local storage.
Whitespace makes that convention visible to humans but does not change AWK
semantics.

This standard therefore requires explicit documentation rather than inference:

```awk
## @param line Record to parse.
## @param separator Field separator to apply.
## @local fields Scratch array populated during parsing.
## @local count Number of fields produced by the split operation.
function parse_record(line, separator,    fields, count) {
```

`@param` identifies caller-supplied formals.  `@local` identifies formal
parameters that callers must omit and that the function uses as local storage.

The following rules apply:

* `@param` names must appear in the function declaration;
* `@local` names must appear in the function declaration;
* every documented caller-supplied formal must use `@param`;
* every conventional local whose purpose is not self-evident should use
  `@local`;
* public parameters must be documented before locals;
* documentation order must match declaration order within each group; and
* tooling must not infer `@param` versus `@local` solely from whitespace.

Projects should retain a visible whitespace separator between caller-supplied
parameters and pseudo-locals in source.  Four spaces is a common and readable
convention:

```awk
function parse_record(line, separator,    fields, count) {
```

That spacing is a human readability convention, not the normative semantic
marker.  `@param` and `@local` are authoritative for documentation.

### Scalar and Array Parameters

AWK does not have a conventional static type system, but scalar and array
parameters behave differently enough that documentation must distinguish them
when it affects callers.

When a parameter is expected to be an array, say so explicitly:

```awk
## @param values Associative array of logical names to values.  The array is
## modified in place to remove invalid entries.
```

When a scalar is interpreted numerically, textually, or in both contexts,
document the semantic expectation rather than inventing a type declaration:

```awk
## @param limit Maximum number of records to accept, interpreted numerically.
```

If an array parameter is mutated, that mutation is part of the caller-visible
contract and must be stated explicitly.  Do not rely on readers to remember AWK
array-parameter semantics while reviewing a function.

### Conventional Locals

Pseudo-local parameters should represent working state whose lifetime is limited
to a function invocation.  Documentation should explain a local when its purpose,
shape, reuse, or ordering role is not obvious.

Do not document every one-character loop variable merely to satisfy a perceived
comment quota.  Documentation volume should preserve reasoning, not create noise
that obscures it.

When a pseudo-local is an array, identify it as such:

```awk
## @local parts Scratch array receiving the fields produced by split().
```

When a pseudo-local deliberately shadows or separates state from a global with a
similar role, explain that relationship.

### Paragraphs for STDIN, STDOUT, and STDERR

Every documented function must contain exactly one `@par STDIN`, one
`@par STDOUT`, and one `@par STDERR`.

These paragraphs describe direct stream behavior of the function itself.

```awk
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Each accepted value is written as one line.
## @par STDERR
## A diagnostic is written when validation fails.
```

For AWK, "reads from STDIN" has a narrower meaning than "uses the current
record."  Accessing `$0`, `$1`, `NF`, `NR`, or other existing record state does
not itself perform a new read from standard input.  A function that consumes
additional records with unredirected `getline` does perform direct input and must
document that behavior.

If a function reads from a file or command using a redirected form of `getline`,
describe that in `@details`, `@par Side Effects`, or another appropriately named
paragraph rather than incorrectly calling it STDIN.

When a function intentionally writes nothing to a stream, state that explicitly.
The negative contract is useful because a maintainer then does not need to read
the implementation to determine whether stream output is intentionally absent.

### Using @returns and @retval

AWK functions have actual language-level return values.  `@returns` therefore
documents the function's AWK return contract.

Every function must have exactly one `@returns` statement.

```awk
## @returns The normalized key string.
```

When a function intentionally has no meaningful return contract, document that
explicitly:

```awk
## @returns No meaningful value; callers must not depend on the return value.
```

Do not describe an AWK function as returning "nothing" when the important
contract is that callers must ignore whatever value results from falling through
or from a bare `return`.  The documentation should describe the caller-visible
promise, not imply a stronger language guarantee than the implementation makes.

Use `@retval` when a function has a small set of discrete, meaningful return
values whose individual meanings improve the contract:

```awk
## @returns A numeric validation result.
## @retval 1 The value satisfies all validation rules.
## @retval 0 The value does not satisfy the validation rules.
```

`@retval` documents AWK return values.  It does not document process exit
statuses.

A function that calls `exit` affects the AWK process rather than merely returning
from the function.  That behavior must be documented as a control-flow or
process-level side effect, for example:

```awk
## @par Side Effects
## Calls exit 2 when the configuration cannot be parsed, terminating the AWK
## program immediately.
```

If an exact process exit status forms part of the public program contract,
document it at file or rule level as well as at the function that triggers it
when that local context is useful.

Do not use `@retval` for text written with `print` or `printf`.  Stream output and
function return values are independent interfaces.

### Relationship Between @returns and @par STDOUT

`@par STDOUT` describes the semantic meaning of text or records written to
standard output by the function and the conditions under which that output is
produced.

`@returns` describes the AWK value produced by the function's `return` behavior.

For example:

```awk
## @par STDOUT
## Writes one diagnostic summary line when the value is rejected.
##
## @returns A numeric validation result.
## @retval 1 The value is accepted.
## @retval 0 The value is rejected.
```

A function may write data to STDOUT and return a value.  Document both behaviors
independently.

### Record Context

Functions that inspect or modify current-record state should document that
relationship explicitly.  Use `@details` or a dedicated `@par Record Context`
section when useful.

Examples of relevant state include:

* `$0`;
* numbered fields such as `$1` and `$2`;
* `NF`;
* `NR` and `FNR`;
* `FILENAME`;
* field or record separators; and
* effects of assigning to `$0`, a numbered field, or `NF`.

Example:

```awk
## @par Record Context
## Reads $1 and $2 from the current record.  The function does not modify $0,
## any field, or NF.
```

Do not hide record-context dependencies inside vague wording such as "uses the
current input."  Name the state that matters.

### Global State

AWK variables referenced by a function are global unless they are formal
parameters.  This makes global-state documentation especially important.

When a function reads or writes significant global state, explain that behavior
in `@details` or use a dedicated `@par Globals` section:

```awk
## @par Globals
## Reads config_by_name.  Increments rejected_record_count when validation
## fails.  No other global state is modified.
```

A function that depends on a global being initialized in `BEGIN` must state that
precondition.

```awk
## @details
## Requires normalize_rules to have been populated by the initialization rule
## before the first input record is processed.
```

When order matters, say so.  "Global" is not enough information to preserve a
lifecycle invariant.

## Variables and Arrays

AWK generally does not declare ordinary variables before use.  A documentation
standard must not pretend that an assignment is equivalent to a declaration or
that the first textual assignment necessarily identifies ownership.

Use `@var` as an explicit documentation declaration for significant global
variables and arrays:

```awk
## @var record_count
## @brief Number of accepted input records processed so far.
## @details
## This global counter is initialized by the initialization rule and incremented
## only after a record has passed validation.
```

For arrays:

```awk
## @var cache_by_key
## @brief Maps normalized keys to cached values.
## @details
## This global associative array is populated lazily by cache_lookup().  Keys
## are normalized strings.  Values are the original payload strings.  Entries
## remain valid for the lifetime of the AWK process.
```

The `@var` name is authoritative documentation metadata.  An adjacent assignment
is not required when no single canonical assignment represents creation or
ownership.

When a variable has one clear top-level initialization and adjacency improves
readability, the documentation block may immediately precede that assignment:

```awk
## @var default_limit
## @brief Default maximum number of accepted records.
default_limit = 100
```

Tooling may validate a simple adjacent initialization when it can do so
conservatively, but the documentation standard must not require the filter to
infer variable existence or type from arbitrary executable statements.

Document globals when their meaning is not self-evident or when they participate
in public behavior, configuration, security, lifecycle, synchronization of
rules, or important state transitions.

For documented variables and arrays, explain as applicable:

* semantic meaning;
* numeric versus textual interpretation;
* units;
* expected key and value shapes;
* mutability;
* ownership;
* initialization point;
* lifetime;
* whether deletion of entries is allowed;
* whether empty string and zero have distinct semantic meaning;
* whether the value is part of public compatibility; and
* which functions or rules are responsible for mutation.

Do not document every transient variable.  Documentation volume should preserve
reasoning, not enumerate syntax.

## Built-In AWK Variables

Built-in AWK variables can form an important part of a program's contract even
though the project does not own their definitions.

When a program materially reads, writes, or depends on a built-in variable,
document the assumption in the file block, relevant rule, or relevant function.
Common examples include:

* `FS` and `OFS`;
* `RS` and `ORS`;
* `SUBSEP`;
* `CONVFMT` and `OFMT`;
* `ARGC` and `ARGV`;
* `ENVIRON`;
* `NR` and `FNR`;
* `NF`;
* `FILENAME`; and
* implementation-specific built-ins established by governing project policy.

Do not use `@var` merely to restate language-provided definitions.  Use `@var`
only when the project establishes meaningful project-owned semantics around that
state.  Otherwise describe the dependency where it affects behavior.

When modifying a built-in variable changes subsequent record parsing or output,
that modification is a side effect and must be documented.

## BEGIN, END, and Pattern/Action Rules

A substantial amount of AWK behavior lives outside named functions.  `BEGIN`,
`END`, and ordinary pattern/action rules are first-class program structure and
must be documentable without pretending they are functions.

Use `@rule` to assign a stable documentation identity to a rule whose behavior is
important enough to preserve in generated reference documentation:

```awk
## @rule initialize
## @brief Initializes separators and global state before input processing.
## @details
## Establishes the invariants required by all later record-processing rules.
##
## @par Trigger
## Runs once during BEGIN processing before the first input record is read.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A diagnostic is written if required configuration is missing.
## @par Side Effects
## Sets FS and OFS and initializes config_by_name.
BEGIN {
    # implementation
}
```

For an ordinary pattern/action rule:

```awk
## @rule process_assignment
## @brief Processes assignment records.
## @details
## Validates the key and stores the normalized value.
##
## @par Trigger
## Runs for records whose first field is the literal string "set".
## @par Record Context
## Reads $1 through $3 and does not rewrite the current record.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A diagnostic is written when the assignment is malformed.
## @par Side Effects
## Updates value_by_key and may increment rejected_record_count.
$1 == "set" {
    # implementation
}
```

`@rule` names are documentation identities.  AWK does not provide source-level
names for ordinary rules.  The name should therefore be stable, descriptive,
and independent of incidental source line numbers.

A documentation block using `@rule` must remain adjacent to the rule it
documents.  The filter may synthesize a Doxygen-friendly declaration using the
rule name, but generated documentation must not imply that the source contains a
callable AWK function with that name.

### Rule Trigger Documentation

Every documented rule must contain exactly one `@par Trigger` describing when the
rule executes.

For `BEGIN`:

```awk
## @par Trigger
## Runs once during BEGIN processing before the first input record is read.
```

For `END`:

```awk
## @par Trigger
## Runs once during END processing after ordinary input processing completes,
## subject to the program's exit behavior.
```

For an ordinary rule, describe the semantic match condition rather than merely
copying a complex regular expression when prose makes the contract clearer.

```awk
## @par Trigger
## Runs for non-empty, non-comment configuration records.
```

When the exact pattern is itself part of the contract, quote or show it in
addition to explaining its meaning.

Range patterns, pattern-only rules, and action-only rules must explain their
execution semantics clearly enough that a maintainer does not need to reconstruct
control flow from syntax alone.

### Rule Output and Side Effects

Document STDOUT and STDERR for rules using the same semantic discipline as for
functions.  Rules do not have AWK return values, so they do not use `@returns` or
`@retval` merely to imitate function documentation.

Document significant effects such as:

* changing global state;
* modifying `$0`, fields, or `NF`;
* changing separators;
* reading additional records;
* writing files;
* invoking commands;
* calling `exit`;
* deleting array entries;
* changing `ARGV`; and
* affecting later rules through global state.

When rule ordering is significant, explain the invariant explicitly.

## getline and Additional Input

`getline` changes program behavior in ways that are easy to overlook during
maintenance.  Any non-trivial use of `getline` must be documented where its
behavior affects the contract.

Documentation should identify as applicable:

* whether input comes from the ordinary input stream, a file, or a command;
* whether `$0` is replaced;
* whether fields are recomputed;
* whether `NR` or `FNR` changes;
* whether the read consumes a record that later rules would otherwise see;
* how EOF and error conditions are handled; and
* whether external resources must be closed.

Do not summarize all forms of `getline` as "reads a line."  The source form and
its effects matter.

## Regular Expressions and Dynamic Patterns

When a regular expression embodies business logic, security policy, parsing
boundaries, or portability assumptions, document its intent rather than merely
restating its syntax.

For dynamic regular expressions, identify the origin and trust level of the
pattern when relevant:

```awk
## @details
## Treats pattern as an AWK regular expression supplied by the caller.  The
## value is not escaped or converted into a fixed-string match.
```

If the implementation performs fixed-string matching by construction, say so.
Do not call a value "literal" when AWK will interpret it as a regular expression.

Locale and multibyte assumptions that materially affect matching must be
identified.  Do not imply byte-oriented behavior if correctness depends on the
active AWK implementation and locale.

## External Commands, Files, and Redirection

AWK can interact with external processes and files through `system()`, output
redirection, pipelines, and `getline`.  Those interactions cross important
boundaries and must be documented when non-trivial.

For command execution, explain as applicable:

* where the command string originates;
* whether untrusted data can influence it;
* whether a shell interprets the command;
* quoting or escaping assumptions;
* expected exit behavior;
* whether output is consumed or discarded; and
* whether the command is part of the public contract or an implementation detail.

For file access, explain as applicable:

* path origin;
* overwrite versus append semantics;
* expected permissions;
* lifecycle and closing behavior;
* whether files are temporary or durable; and
* failure behavior.

Do not use comments to imply that command strings or paths are safe merely
because they originated inside AWK.  Safety depends on how data is constructed
and interpreted.

## Process Exit Behavior

AWK functions return values; AWK programs may also terminate with `exit`.
These are different interfaces.

Process exit behavior should be documented at the file level when it forms part
of the program's public contract.  Use a dedicated paragraph when helpful:

```awk
## @par Exit Status
## 0 indicates successful processing.  2 indicates invalid configuration.
```

Functions or rules that call `exit` must also document that local control-flow
side effect.

Do not use function `@retval` lines to describe process exit statuses.

When the implementation can propagate an implementation-defined or external
status, state that fact without inventing a normalized value the program does not
actually guarantee.

## Internal Helpers

Internal naming conventions are project-specific.  A leading underscore,
double underscore, or project-specific prefix may communicate maintainer intent,
but it is not a privacy mechanism and is not a reason to omit documentation from
a security-critical or architecturally important helper.

Internal functions should still receive complete function documentation when a
future maintainer would otherwise need to infer their contracts, state effects,
or ordering requirements from executable code.

Do not equate "internal" with "unimportant."

## Security-Sensitive Documentation

For redaction, validation, parsing, command execution, file emission, and other
security-sensitive AWK code, comments should make it possible for a reviewer to
answer questions such as:

* what untrusted or sensitive state the function or rule receives or accesses;
* whether values originate from records, `ARGV`, `ENVIRON`, files, or commands;
* whether data is interpreted as a regular expression;
* whether data is incorporated into a shell command;
* whether data can reach STDOUT, STDERR, a file, or a subprocess;
* whether failure suppresses output or emits original input;
* whether replacement text is interpreted or treated literally;
* whether array keys or values can contain attacker-controlled data;
* whether locale or multibyte behavior matters;
* whether parsing depends on `FS`, `RS`, or other mutable built-ins;
* which AWK implementation or compatibility floor is assumed; and
* which ADR establishes the relevant security promise.

Do not use comments to imply stronger runtime protection than AWK provides.
Terms such as "private," "secure memory," "isolated," or "sanitized" must not be
used unless a real mechanism or clearly defined transformation supports the
claim.

When command execution is involved, documentation must distinguish fixed command
text from command text influenced by data.  Shell interpretation must not be
left implicit.

## Document Intent, Not Syntax

Avoid comments such as "increment the counter" immediately above:

```awk
count++
```

Prefer comments that explain why the counter exists, why the increment occurs at
that point in the rule sequence, what invariant it participates in, or why a
seemingly unusual implementation is necessary.

If code and documentation disagree, treat the disagreement as a defect to
investigate.  Do not automatically rewrite the comment to match current code;
the code may be the part that drifted from the intended contract.

Documentation should preserve decisions and constraints that are not obvious
from AWK syntax alone.

## Relationship to ADRs

Doxygen documentation owns implementation-level intent.  ADRs own durable
architectural reasoning, promises, non-promises, adversary and failure models,
rejected alternatives, and accepted tradeoffs.

Source comments may link to an ADR when a local implementation exists
specifically to satisfy an architectural constraint.

Do not copy an entire ADR into source comments.  Do not invent historical
rationale when no source supports it.  State uncertainty or add an ADR when a
new consequential decision is required.

`doc/decisions.md`, when present, provides concise ADR summaries and does not
replace either the full ADR or local Doxygen contracts.

When a project has a consumer-facing specification, public AWK documentation
should agree with that specification while adding implementation-level context
that would be inappropriate in the consumer-facing document.

## Generated Reference Documentation

Projects adopting `awk-doxygen` may generate Doxygen reference documentation
from maintained source.  Generated output is derivative and is not a maintained
source of truth.

The maintained AWK source and its Doxygen blocks remain authoritative for local
implementation contracts.  Generated pseudo-language output exists only to make
those contracts indexable by Doxygen.

If a project creates generated, stripped, or compact consumer artifacts, that
build process may remove documentation according to governing project decisions.
Maintainers should not shorten source comments merely because a consumer artifact
has a size constraint.

## General File Structure Pattern

A maintained AWK file should generally follow this structure when applicable:

1. optional governed shebang;
2. `@file`;
3. `@brief` for the file;
4. substantive `@details` for the file;
5. `@author`, `@copyright`, `@see`, `@note`, and `@warning` as needed;
6. significant documented global variables and arrays;
7. named functions;
8. `BEGIN` rule or rules;
9. ordinary pattern/action rules; and
10. `END` rule or rules.

This ordering is a documentation-oriented default rather than a semantic AWK
requirement.  Projects may establish a different governed source structure when
execution order, generated assembly, readability, or existing architecture
requires it.

Do not reorder rules merely to satisfy this list when rule order is part of
program behavior.

## General Function Structure Pattern

A documented AWK function should generally use the following structure:

1. `@fn`;
2. `@brief`;
3. `@details`;
4. additional `@note`, `@warning`, `@see`, `@par Record Context`,
   `@par Globals`, and `@par Side Effects` directives as needed;
5. blank line;
6. zero or more `@param` directives in declaration order;
7. zero or more `@local` directives in declaration order;
8. blank line;
9. exactly one `@par STDIN`;
10. exactly one `@par STDOUT`;
11. exactly one `@par STDERR`;
12. blank line;
13. exactly one `@returns`;
14. zero or more `@retval` directives for discrete AWK return values;
15. `@par Examples` when an example materially improves understanding;
16. `@code`;
17. example lines; and
18. `@endcode`.

The optional contextual paragraphs should appear where they make the contract
clearest.  Structural consistency is valuable, but preserving the reader's
ability to understand the interface is the higher goal.

## General Rule Structure Pattern

A documented AWK rule should generally use the following structure:

1. `@rule`;
2. `@brief`;
3. `@details`;
4. additional `@note`, `@warning`, and `@see` directives as needed;
5. blank line;
6. exactly one `@par Trigger`;
7. `@par Record Context` when the rule depends materially on current-record
   state;
8. exactly one `@par STDOUT`;
9. exactly one `@par STDERR`;
10. `@par Side Effects` when the rule changes meaningful global, process, file,
    or command state; and
11. `@par Examples` with `@code` / `@endcode` when an example materially improves
    understanding.

Rules do not use `@returns` or `@retval` merely to imitate function structure.
If a rule calls `exit`, document process termination under side effects and, when
part of the public interface, in the file-level exit-status contract.

## Review Standard

Review documentation with the same seriousness as executable code.  Ask whether
a maintainer unfamiliar with the current implementation could understand:

* the responsibility of each AWK file or module;
* the contract of each function;
* the distinction between caller parameters and conventional locals;
* which arrays are mutated and which values are returned;
* direct STDIN, STDOUT, and STDERR behavior;
* dependencies on current-record state;
* dependencies on global state and initialization order;
* the trigger and effects of important `BEGIN`, `END`, and pattern/action rules;
* assumptions involving `FS`, `RS`, `OFS`, `ORS`, `ARGV`, `ENVIRON`, or other
  built-in variables;
* important input, output, and process-exit semantics;
* invariants and ordering requirements;
* meaningful edge cases and failure modes;
* regular-expression interpretation and trust boundaries;
* subprocess, pipeline, file, and redirection boundaries;
* portability assumptions and implementation-specific dependencies;
* security-sensitive state and output boundaries;
* why non-obvious implementation choices exist;
* which architectural decisions constrain future changes; and
* what the implementation explicitly does not guarantee.

There is no target comment-to-code ratio.  The desired amount is "enough to
preserve the reasoning."  In projects adopting this standard, that may often be
more prose than teams accustomed to sparse AWK comments expect, and that is
intentional.

## Structural Checklist

Before considering a maintained AWK file adequately documented, verify as
applicable:

* the file has `## @file`, `## @brief`, and substantive `## @details`;
* any shebang is governed by project execution policy rather than assumed by this
  standard;
* all maintained functions have `@fn`, `@brief`, and `@details`;
* caller-supplied parameters are documented with `@param` in declaration order;
* conventional pseudo-locals are documented with `@local` where their purpose is
  not self-evident;
* tooling and reviewers do not infer public-versus-local semantics solely from
  whitespace;
* array parameters identify whether callers should expect mutation;
* every function contains exactly one `@par STDIN`, one `@par STDOUT`, one
  `@par STDERR`, and one `@returns`;
* discrete AWK return values use `@retval` only when doing so improves the
  contract;
* process exit statuses are not mislabeled as function return values;
* functions that depend on `$0`, fields, `NF`, `NR`, `FNR`, `FILENAME`, or other
  record state document that dependency;
* functions that read or modify significant globals document the dependency and
  lifecycle assumptions;
* significant global variables and arrays use `@var` where useful;
* documented `BEGIN`, `END`, and pattern/action rules use stable `@rule` names;
* every documented rule contains exactly one `@par Trigger`;
* documented rules describe meaningful output, diagnostics, and side effects;
* non-trivial `getline` use documents its source and record-state effects;
* command execution, pipelines, file writes, and dynamic regular expressions
  document their interpretation and trust assumptions;
* public or non-trivial functions and rules contain examples when an example
  materially improves understanding;
* documentation blocks remain adjacent to functions and rules consumed by
  `awk-doxygen`;
* `@var` blocks identify ownership even when no single adjacent assignment can
  serve as a declaration;
* implementation-specific AWK behavior is identified explicitly rather than
  described as portable by implication; and
* security-sensitive code documents assumptions a future reviewer would otherwise
  have to infer.

## Summary

This standard treats AWK source documentation as part of the maintained program
contract.  The goal is not to decorate syntax.  The goal is to preserve the
reasoning, state model, execution model, and boundaries that a future maintainer
would otherwise have to reconstruct from code.

AWK's small syntax does not make its behavioral contracts small.  Global state,
record context, implicit conversions, regular-expression interpretation,
pattern/action ordering, `getline`, subprocess execution, and pseudo-local
function parameters can all hide important assumptions behind compact source.
Documentation should make those assumptions explicit.

When in doubt, prefer the explanation that allows the next maintainer to change
the code safely without first reverse-engineering why the current implementation
works.
