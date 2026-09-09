# shellcheck shell=bash
## @file lib/plugins/input/dot.bash
## @brief Registers the built-in authored Graphviz DOT representation.
## @details
## This additive leaf module is discovered only by the build.  Once assembled,
## its top-level registration records that `dot` source payloads materialize as
## `.dot` files.  Graphical output plugins may declare this source as their input
## without adding format-name branches to the core orchestrator.

figurectl_input_register "dot" "dot"
