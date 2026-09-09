# shellcheck shell=bash
## @file lib/plugins/output/svg.bash
## @brief Registers Graphviz SVG publication output.
## @details
## SVG output consumes authored `dot`, renders the materialized source through the
## shared Graphviz renderer, and replaces the selected figure with a Markdown
## image reference ending in `.svg`.

figurectl_output_register \
  "svg" \
  "dot" \
  "image" \
  "svg" \
  "figurectl_render_graphviz" \
  ""
