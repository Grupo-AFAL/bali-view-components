# frozen_string_literal: true

require "test_helper"

class BaliChartComponentTest < ComponentTestCase
  def setup
    @component = Bali::Chart::Component.new(data: { chocolate: 3 })
  end

  def test_rendering_renders_a_chart_title_with_daisyui_card_classes
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, title: "Chocolate Sales", id: "chocolate-sales", card_style: :default))
    assert_selector("h3.card-title", text: "Chocolate Sales")
    assert_selector(".card.bg-base-100")
  end

  def test_rendering_renders_title_without_card_by_default
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, title: "Chocolate Sales"))
    assert_selector("h3", text: "Chocolate Sales")
    assert_no_selector(".card")
  end

  def test_rendering_renders_a_div_with_chart_controller
    render_inline(@component)
    assert_selector("canvas.chart")
    assert_selector('canvas[data-controller="chart"]')
  end

  def test_rendering_renders_without_title_when_not_provided
    render_inline(@component)
    assert_no_selector("h3")
  end

  def test_chart_types_renders_a_bar_chart_by_default
    render_inline(@component)
    assert_selector('canvas[data-chart-type-value="bar"]')
  end

  def test_chart_types_renders_a_line_chart
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, type: :line))
    assert_selector('canvas[data-chart-type-value="line"]')
  end

  def test_chart_types_renders_a_pie_chart
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, type: :pie))
    assert_selector('canvas[data-chart-type-value="pie"]')
  end

  def test_chart_types_renders_a_doughnut_chart
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, type: :doughnut))
    assert_selector('canvas[data-chart-type-value="doughnut"]')
  end

  def test_chart_types_renders_a_polararea_chart
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, type: :polarArea))
    assert_selector('canvas[data-chart-type-value="polarArea"]')
  end

  def test_data_attributes_includes_chart_data_as_json
    render_inline(@component)
    canvas = page.find("canvas.chart")
    assert_includes(canvas["data-chart-data-value"], "chocolate")
  end

  def test_data_attributes_includes_display_percent_value_when_enabled
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, display_percent: true))
    canvas = page.find("canvas.chart")
    assert_equal("true", canvas["data-chart-display-percent-value"])
  end

  def test_string_keys_reads_the_multi_series_format_written_with_string_keys
    render_inline(Bali::Chart::Component.new(
      data: {
        "labels" => %w[Mon Tue],
        "datasets" => [ { "label" => "Beef", "data" => [ 10, 5 ] } ]
      }
    ))
    canvas = page.find("canvas.chart")
    assert_equal(%w[Mon Tue], JSON.parse(canvas["data-chart-labels-value"]))

    payload = JSON.parse(canvas["data-chart-data-value"])
    assert_equal(%w[Mon Tue], payload["labels"])
    assert_equal(1, payload["datasets"].size)
    assert_equal("Beef", payload["datasets"].first["label"])
    assert_equal([ 10, 5 ], payload["datasets"].first["data"])
  end

  def test_string_keys_still_reads_the_simple_format_written_with_string_keys
    render_inline(Bali::Chart::Component.new(data: { "Mon" => 10, "Tue" => 20 }))
    canvas = page.find("canvas.chart")
    assert_equal(%w[Mon Tue], JSON.parse(canvas["data-chart-labels-value"]))
    assert_equal([ 10, 20 ], JSON.parse(canvas["data-chart-data-value"])["datasets"].first["data"])
  end

  # Theme styling used to index `scales` with String keys while a caller's
  # `options:` naturally carries Symbols, so the two never merged: the JSON
  # carried `"x"` twice (an error under json 3.0) and whichever entry the
  # browser kept last silently erased the other side's config (#1066).
  def test_scales_merges_callers_symbol_keyed_scales_into_the_theme_axis_config
    render_inline(Bali::Chart::Component.new(
      data: { chocolate: 3 },
      options: { scales: { x: { display: false }, y: { display: false, beginAtZero: true } } }
    ))
    raw = page.find("canvas.chart")["data-chart-options-value"]
    assert_equal(1, raw.scan('"x":').size)
    assert_equal(1, raw.scan('"y":').size)

    scales = JSON.parse(raw)["scales"]
    assert_equal(false, scales["x"]["display"])
    assert_equal(true, scales["y"]["beginAtZero"])
    assert_equal(true, scales["x"]["ticks"]["useThemeColors"])
    assert_equal(true, scales["y"]["grid"]["display"])
  end

  def test_scales_merges_callers_string_keyed_scales_too
    render_inline(Bali::Chart::Component.new(
      data: { chocolate: 3 },
      options: { "scales" => { "x" => { "display" => false } } }
    ))
    raw = page.find("canvas.chart")["data-chart-options-value"]
    assert_equal(1, raw.scan('"scales":').size)
    assert_equal(1, raw.scan('"x":').size)

    x_axis = JSON.parse(raw)["scales"]["x"]
    assert_equal(false, x_axis["display"])
    assert_equal(true, x_axis["ticks"]["useThemeColors"])
  end

  def test_plugins_merges_callers_string_keyed_plugins_into_the_theme_config
    render_inline(Bali::Chart::Component.new(
      data: { chocolate: 3 },
      options: { "plugins" => { "tooltip" => { "enabled" => false } } }
    ))
    raw = page.find("canvas.chart")["data-chart-options-value"]
    assert_equal(1, raw.scan('"plugins":').size)
    assert_equal(1, raw.scan('"tooltip":').size)

    tooltip = JSON.parse(raw)["plugins"]["tooltip"]
    assert_equal(false, tooltip["enabled"])
    assert_equal(true, tooltip["useThemeColors"])
  end

  def test_constants_has_max_label_length_constant
    assert_equal(16, Bali::Chart::Component::MAX_LABEL_LENGTH)
  end

  def test_constants_has_multi_color_types_constant
    assert_equal(%i[pie doughnut polarArea], Bali::Chart::Component::MULTI_COLOR_TYPES)
  end

  def test_constants_has_default_options_constant
    assert_equal({ responsive: true, maintainAspectRatio: false, animation: { duration: 800, easing: "easeOutQuart" } }, Bali::Chart::Component::DEFAULT_OPTIONS)
  end

  def test_options_passthrough_accepts_custom_html_attributes
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, id: "my-chart", class: "custom-class"))
    assert_selector(".chart-container#my-chart.custom-class")
  end

  def test_card_styles_renders_without_card_by_default
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
    assert_no_selector(".card")
    assert_selector(".chart-component")
  end

  def test_card_styles_renders_with_bordered_card_style
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, card_style: :bordered))
    assert_selector(".card.bg-base-100.card-border")
  end

  def test_card_styles_renders_with_compact_card_style
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, card_style: :compact))
    assert_selector(".card.bg-base-100.card-compact")
  end

  def test_card_styles_renders_without_card_when_style_is_none
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, card_style: :none))
    assert_no_selector(".card")
    assert_selector(".chart-component")
  end

  def test_height_presets_renders_with_medium_height_by_default
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
    assert_selector(".chart-container.h-\\[250px\\]")
  end

  def test_height_presets_renders_with_small_height
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, height: :sm))
    assert_selector(".chart-container.h-\\[180px\\]")
  end

  def test_height_presets_renders_with_large_height
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, height: :lg))
    assert_selector(".chart-container.h-\\[350px\\]")
  end

  def test_height_presets_renders_with_extra_large_height
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, height: :xl))
    assert_selector(".chart-container.h-\\[450px\\]")
  end

  def test_theme_colors_sets_use_theme_colors_data_attribute
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
    assert_selector('canvas[data-chart-use-theme-colors-value="true"]')
  end

  def test_theme_colors_can_disable_theme_colors
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, use_theme_colors: false))
    assert_selector('canvas[data-chart-use-theme-colors-value="false"]')
  end

  # Everything Chart.js draws is pixels. Without a role and a name the canvas is
  # an unlabelled node the accessibility tree walks straight past.
  def test_a11y_canvas_is_an_image_named_after_the_title
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, title: "Chocolate Sales"))
    assert_selector('canvas[role="img"][aria-label="Chocolate Sales"]')
  end

  def test_a11y_aria_label_overrides_the_title
    render_inline(Bali::Chart::Component.new(
      data: { chocolate: 3 }, title: "Sales", aria_label: "Monthly chocolate sales, 2026"
    ))
    assert_selector('canvas[aria-label="Monthly chocolate sales, 2026"]')
  end

  # A generic name beats no name: an unnamed `role="img"` is announced as
  # nothing at all.
  def test_a11y_falls_back_to_a_generic_name_without_a_title
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
    assert_selector('canvas[aria-label="Chart"]')
  end

  def test_a11y_translates_the_fallback_name
    I18n.with_locale(:es) do
      render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
      assert_selector('canvas[aria-label="Gráfica"]')
    end
  end

  def test_a11y_names_the_canvas_inside_a_card_too
    render_inline(Bali::Chart::Component.new(
      data: { chocolate: 3 }, title: "Sales", card_style: :default
    ))
    assert_selector('canvas[role="img"][aria-label="Sales"]')
  end

  # `role="img"` gives the chart a name, not its numbers. The slot is the only
  # way a screen reader user reads a value off it. The wrapper class is Bali's
  # own, not the `sr-only` utility: without JS the canvas never draws and the
  # chart left a container-height hole, so chart/index.css reveals this table
  # under `@media (scripting: none)` — an override that has to live in the
  # same layer as the hiding it undoes, which a template utility cannot (#1067).
  def test_a11y_renders_the_data_table_slot_for_screen_readers
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 })) do |c|
      c.with_data_table { "<table><tr><td>Chocolate</td><td>3</td></tr></table>".html_safe }
    end
    assert_selector("div.chart-fallback-table table td", text: "Chocolate")
    assert_no_selector("div.sr-only")
  end

  def test_a11y_renders_the_data_table_slot_inside_a_card
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, card_style: :default)) do |c|
      c.with_data_table { "<table><tr><td>Chocolate</td><td>3</td></tr></table>".html_safe }
    end
    assert_selector(".card-body div.chart-fallback-table table td", text: "Chocolate")
  end

  # The no-JS reveal hides the empty canvas box through a `:has(+ .chart-fallback-table)`
  # sibling selector, so the wrapper must stay the container's next sibling in
  # both layouts.
  def test_a11y_fallback_table_is_the_containers_next_sibling
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 })) do |c|
      c.with_data_table { "<table><tr><td>Chocolate</td><td>3</td></tr></table>".html_safe }
    end
    assert_selector(".chart-container + .chart-fallback-table")

    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }, card_style: :default)) do |c|
      c.with_data_table { "<table><tr><td>Chocolate</td><td>3</td></tr></table>".html_safe }
    end
    assert_selector(".chart-container + .chart-fallback-table")
  end

  def test_a11y_renders_no_table_wrapper_without_the_slot
    render_inline(Bali::Chart::Component.new(data: { chocolate: 3 }))
    assert_no_selector("div.chart-fallback-table")
  end
end
