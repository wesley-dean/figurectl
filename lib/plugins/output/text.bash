# shellcheck shell=bash
## @file lib/plugins/output/text.bash
## @brief Registers fenced text publication output.
## @details
## Text output consumes authored `text`, materializes `.txt`, and replaces the
## selected figure with a fenced `text` block.  No renderer subprocess is needed.

figurectl_output_register "text" "text" "fence" "txt" "" "text"
