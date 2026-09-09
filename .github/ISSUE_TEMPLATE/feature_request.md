---
name: Feature request
about: Propose a new figurectl capability or contract change
title: ""
labels: enhancement
assignees: ""
---

## Problem or need

<!--
Describe the concrete figure-processing problem.  What becomes difficult, unsafe,
repetitive, or unclear without this change?
-->

## Proposed behavior

<!--
Describe the public or developer-visible behavior you want.  Prefer the contract
you need over a particular implementation when possible.
-->

## Promises and non-promises

<!--
What should callers be able to rely upon?  What should they explicitly not infer
from the feature?
-->

## Alternatives considered

<!--
Could an existing figurectl command/format, caller-owned composition, Graphviz,
Make, an existing reviewed dependency, or a smaller API solve the problem?
-->

## Architecture and compatibility impact

<!--
Does this add or change a public command, option, authored source format,
publication output format, artifact, Make target, metadata key, runtime assumption,
build-time plugin contract, or compatibility commitment?

If it proposes runtime/external plugin loading, explain why the current
build-time-only plugin model is insufficient; ADR-018 requires a new architectural
decision for that boundary.
-->

## Security and dependency impact

<!--
Does this change untrusted-input parsing, generated paths, filesystem/network
authority, Graphviz or other subprocess execution, dynamic loading, CI/release
authority, or add a dependency?  If so, identify the new trust boundary or attack
surface and any expected residual risk.
-->

## Additional context

<!-- Add examples, prior art, links, or other useful context. -->
