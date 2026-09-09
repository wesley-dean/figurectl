# shellcheck shell=bash
## @file lib/plugins/input/text.bash
## @brief Registers the built-in authored text figure representation.
## @details
## This additive leaf module is discovered only by the build.  Once assembled,
## its top-level registration records that `text` source payloads materialize as
## `.txt` files.  The released artifact does not read this pathname at runtime.

figurectl_input_register "text" "txt"
