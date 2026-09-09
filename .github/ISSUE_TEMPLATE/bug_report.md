---
name: Bug report
about: Report reproducible unexpected figurectl behavior
title: ""
labels: bug
assignees: ""
---

## What happened?

<!-- Describe the unexpected behavior clearly and concisely. -->

## What did you expect?

<!-- Describe the behavior you expected from the documented figurectl contract. -->

## Minimal reproduction

<!--
Provide the smallest figurectl command and Markdown input, or the smallest build
state / Make invocation, that reproduces the problem.  Remove credentials, tokens,
private data, and unrelated application content.
-->

```bash
# reproduction here
```

## Environment

- figurectl release or commit:
- artifact flavor, if relevant (`figurectl.dev.bash`, `figurectl.bash`, or
  `figurectl.min.bash`):
- Bash version (`bash --version`):
- AWK implementation/version, when known:
- Graphviz version (`dot -V`), if graphical rendering is involved:
- operating system/distribution:
- command or Make target:

## Observable result

<!--
Include relevant stdout, stderr, exit status, generated files, or shell state.
Please distinguish stdout from stderr when the difference matters.
-->

```text
output here
```

## Figure input / generated assets

<!--
Include the smallest figure directive/payload that reproduces the issue and list
relevant generated .txt, .dot, .svg, or .png paths.  Avoid attaching sensitive
manuscript or repository content when a synthetic example is sufficient.
-->

## Additional context

<!--
Mention relevant options such as --format, --figures-dir, --dot-style,
--link-prefix, or --output; dependency state; environment variables; and whether
the problem reproduces from a clean checkout or standalone release artifact.
-->

## Security note

Do not place suspected vulnerability details, real credentials, tokens, or private
data in a public issue.  Follow `SECURITY.md` for private vulnerability reporting.
