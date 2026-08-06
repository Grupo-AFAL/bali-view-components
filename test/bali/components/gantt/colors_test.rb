# frozen_string_literal: true

require "test_helper"

# Visual-parity contract with the React island's ganttColors.js: every string
# here is asserted VERBATIM. If a formula must change, change it in both
# runtimes (phase 2 ports the island) or bars will differ between renderers.
class BaliGanttColorsTest < ActiveSupport::TestCase
  def test_neutral_matches_gantt_colors_js
    assert_equal(
      {
        solid: "color-mix(in oklch, var(--color-base-content) 42%, transparent)",
        fill: "color-mix(in oklch, var(--color-base-content) 10%, transparent)",
        border: "color-mix(in oklch, var(--color-base-content) 30%, transparent)",
        text: "color-mix(in oklch, var(--color-base-content) 62%, transparent)"
      },
      Bali::Gantt::Colors.neutral
    )
  end

  def test_var_color_matches_gantt_colors_js
    assert_equal(
      {
        solid: "var(--color-info)",
        fill: "color-mix(in oklch, var(--color-info) 16%, transparent)",
        border: "color-mix(in oklch, var(--color-info) 50%, transparent)",
        text: "var(--color-info)"
      },
      Bali::Gantt::Colors.var_color("--color-info")
    )
  end

  def test_default_status_map_matches_the_island
    assert_equal "var(--color-info)", Bali::Gantt::Colors.status_color("in_progress")[:solid]
    assert_equal "var(--color-warning)", Bali::Gantt::Colors.status_color("ready_for_review")[:solid]
    assert_equal "var(--color-success)", Bali::Gantt::Colors.status_color(:complete)[:solid]
    assert_equal Bali::Gantt::Colors.neutral, Bali::Gantt::Colors.status_color("backlog")
    assert_equal Bali::Gantt::Colors.neutral, Bali::Gantt::Colors.status_color("cancelled")
    assert_equal Bali::Gantt::Colors.neutral, Bali::Gantt::Colors.status_color("unknown")
  end

  def test_custom_status_vocabularies_map_through_vars
    vars = { "done" => "--color-success" }

    assert_equal "var(--color-success)", Bali::Gantt::Colors.status_color("done", vars: vars)[:solid]
    assert_equal Bali::Gantt::Colors.neutral, Bali::Gantt::Colors.status_color("todo", vars: vars)
  end

  def test_hue_color_matches_gantt_colors_js
    assert_equal(
      {
        solid: "oklch(0.62 0.15 25)",
        fill: "oklch(0.62 0.15 25 / 0.15)",
        border: "oklch(0.6 0.15 25 / 0.5)",
        text: "oklch(0.46 0.16 25)"
      },
      Bali::Gantt::Colors.hue_color(25)
    )
    assert_equal Bali::Gantt::Colors.neutral, Bali::Gantt::Colors.hue_color(nil)
  end

  def test_hash_hue_matches_the_js_algorithm
    # h = (h * 31 + charCode) % 360 over the string — hand-computed references.
    assert_equal 0, Bali::Gantt::Colors.hash_hue("")
    assert_equal 97 % 360, Bali::Gantt::Colors.hash_hue("a")
    assert_equal ((97 * 31) + 98) % 360, Bali::Gantt::Colors.hash_hue("ab")
    assert_equal Bali::Gantt::Colors.hash_hue("7"), Bali::Gantt::Colors.hash_hue(7)
  end

  def test_hash_hue_stays_in_range
    assert_includes 0...360, Bali::Gantt::Colors.hash_hue("Ana Luz Durán")
  end
end
