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
end
