# shellcheck shell=bash
## @file lib/plugins/output/dot.bash
## @brief Registers fenced Graphviz DOT publication output.
## @details
## DOT output consumes authored `dot`, materializes `.dot`, and replaces the
## selected figure with a fenced `dot` block.  No renderer subprocess is needed.

figurectl_output_register "dot" "dot" "fence" "dot" "" "dot"
