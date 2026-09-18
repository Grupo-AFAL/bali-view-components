# frozen_string_literal: true

require "test_helper"

# The Reveal trigger used to carry its default spacing as `pb-6 mb-6` on the
# button itself, which a host could not beat without `!` (#1148): utilities
# written on the element land in @layer utilities next to the host's own, where
# specificity ties and only source order decides — and Tailwind emits every
# spacing family in ascending order (`.ml-0` sits immediately before `.ml-1` in
# the dummy build), so Bali's 6 sorted after the host's 0 by construction. The
# chevron's `h-3.5` was the same defect against `icon_class:`.
#
# The fix moves those defaults into the component sheet, inside @layer
# components, which the utilities layer beats outright. This keeps that arrangement
# honest: the sheet has to declare them, and components.css has to import
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

  # The chevron's height, moved for the same reason as the spacing: written
  # beside `icon_class` in one attribute, `icon_class: "h-2"` lost the tie.
  def test_the_sheet_carries_the_trigger_icon_height
    rule = SHEET.read[/\.trigger-icon\s*\{[^}]*\}/]

    assert(rule, "reveal/index.css declares no `.trigger-icon` rule")
    assert_includes(rule, "h-3.5")
  end

  # `select`, not `find`: one layered import at the top does not stop a second,
  # unlayered import of the same sheet being appended later — the unlayered
  # group at the bottom of components.css is a real place and it grows. Two
  # imports would undo the fix with every other assertion here still green.
  def test_components_css_imports_the_sheet_exactly_once_and_layered
    import_lines = COMPONENTS_CSS.read.lines.select { |l| l.include?("reveal/index.css") }

    assert_equal(
      1, import_lines.size,
      "bali/components.css must import the reveal sheet exactly once, got: #{import_lines.inspect}"
    )
    import_lines.each do |line|
      assert_match(
        /layer\(components\)/, line,
        "reveal/index.css must be imported layered — unlayered it would beat host utilities again"
      )
    end
  end
end
