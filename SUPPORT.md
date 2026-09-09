# Getting Support

For ordinary `figurectl` questions, unexpected behavior, and reproducible bug
reports, open an issue in this repository.

A useful report includes enough information to distinguish parser behavior,
runtime portability, renderer behavior, and build/release behavior where relevant:

1. the `figurectl` release or commit being used;
2. the artifact flavor (`figurectl.dev.bash`, `figurectl.bash`, or
   `figurectl.min.bash`), when applicable;
3. Bash version (`bash --version`);
4. AWK implementation and version, when known;
5. Graphviz version (`dot -V`) for SVG/PNG or DOT-style problems;
6. operating system or distribution;
7. the exact command or Make target that failed;
8. the smallest Markdown input or repository state that reproduces the problem;
9. expected behavior and actual behavior; and
10. relevant standard output, standard error, exit status, and generated files.

Please remove credentials, tokens, private data, and unrelated application content
from public reproductions.

## Runtime Baseline

The v1.0 runtime contract is Bash 4.3 or newer plus portable AWK.  Graphviz `dot`
is required only when SVG or PNG rendering is requested.

The released Bash artifacts are standalone.  Runtime external plugins, plugin
search paths, dynamic sourcing, and third-party plugin installation are not
supported by the current product.

## Build and Development Problems

GNU Make is the canonical project orchestration surface.  When reporting a build,
test, dependency, documentation, or release problem, include the Make target and
whether dependency state had been prepared with `make deps`.

`make deps` may use the network.  `make deps-check`, `make build`, `make test`,
`make test-report`, and `make docs` consume prepared dependency state and should
not silently repair it.

## Security Reports

Do not include suspected vulnerability details, real credentials, tokens, or
private data in a public issue.  Follow `SECURITY.md` for private vulnerability
reporting and coordinated disclosure.
