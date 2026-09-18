# frozen_string_literal: true

require "test_helper"

# The Reveal trigger used to carry its default spacing as `pb-6 mb-6` on the
# button itself, which a host could not beat without `!` (#1148): utilities
# written on the element land in @layer utilities next to the host's own, where
# specificity ties and only source order decides — and Tailwind emits every
# spacing family in ascending order (`.ml-0` sits immediately before `.ml-1` in
# the dummy build), so Bali's 6 sorted after the host's 0 by construction.
#
# The fix moves both defaults into the component sheet, inside @layer
# components, which the utilities layer beats outright. This keeps that arrangement
# honest: the sheet has to declare the spacing, and components.css has to import
# it LAYERED. An import cleanup that dropped `layer(components)` would put the
# defaults back on top of host utilities while every render assertion stayed green.
class BaliRevealSpacingCssTest < ActiveSupport::TestCase
  SHEET = Bali::Engine.root.join("app/components/bali/reveal/index.css")
  COMPONENTS_CSS = Bali::Engine.root.join("app/assets/stylesheets/bali/components.css")

  def test_the_sheet_carries_the_trigger_spacing
    assert(SHEET.exist?, "app/components/bali/reveal/index.css is missing")
    rule = SHEET.read[/\.reveal-trigger\s*\{[^}]*\}/]

    assert(rule, "reveal/index.css declares no `.reveal-trigger` rule")
    assert_includes(rule, "pb-6")
    assert_includes(rule, "mb-6")
  end

  def test_the_sheet_carries_the_content_spacing
    rule = SHEET.read[/\.reveal-content\s*\{[^}]*\}/]

    assert(rule, "reveal/index.css declares no `.reveal-content` rule")
    assert_includes(rule, "mb-8")
  end

  def test_components_css_imports_the_sheet_inside_layer_components
    import_line = COMPONENTS_CSS.read.lines.find { |l| l.include?("reveal/index.css") }

    assert(import_line, "bali/components.css no longer imports the reveal sheet")
    assert_match(
      /layer\(components\)/, import_line,
      "reveal/index.css must be imported layered — unlayered it would beat host utilities again"
    )
  end
end
