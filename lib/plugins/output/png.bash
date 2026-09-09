# shellcheck shell=bash
## @file lib/plugins/output/png.bash
## @brief Registers Graphviz PNG publication output.
## @details
## PNG output consumes authored `dot`, renders the materialized source through the
## shared Graphviz renderer, and replaces the selected figure with a Markdown
## image reference ending in `.png`.

figurectl_output_register \
  "png" \
  "dot" \
  "image" \
  "png" \
  "figurectl_render_graphviz" \
  ""
