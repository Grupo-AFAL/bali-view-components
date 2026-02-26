# frozen_string_literal: true

require "test_helper"

class BaliProgressComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_progress_component_with_daisyui_classes
    render_inline(Bali::Progress::Component.new(value: 50))
    assert_selector("div.flex.items-center.gap-2")
    assert_selector('progress.progress.w-full[value="50"][max="100"]')
  end

  def test_basic_rendering_renders_percentage_by_default
    render_inline(Bali::Progress::Component.new(value: 75))
    assert_selector("span", text: "75%")
  end

  def test_basic_rendering_hides_percentage_when_show_percentage_is_false
    render_inline(Bali::Progress::Component.new(value: 50, show_percentage: false))
    assert_no_selector("span")
  end
  #

  def test_colors_renders_primary_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :primary))

    assert_selector("progress.progress.progress-#{:primary}")
  end

  def test_colors_renders_secondary_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :secondary))

    assert_selector("progress.progress.progress-#{:secondary}")
  end

  def test_colors_renders_accent_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :accent))

    assert_selector("progress.progress.progress-#{:accent}")
  end

  def test_colors_renders_neutral_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :neutral))

    assert_selector("progress.progress.progress-#{:neutral}")
  end

  def test_colors_renders_info_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :info))

    assert_selector("progress.progress.progress-#{:info}")
  end

  def test_colors_renders_success_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :success))

    assert_selector("progress.progress.progress-#{:success}")
  end

  def test_colors_renders_warning_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :warning))

    assert_selector("progress.progress.progress-#{:warning}")
  end

  def test_colors_renders_error_color
    render_inline(Bali::Progress::Component.new(value: 50, color: :error))

    assert_selector("progress.progress.progress-#{:error}")
  end
  #

  def test_percentage_calculation_calculates_percentage_from_value_and_max
    render_inline(Bali::Progress::Component.new(value: 25, max: 50))
    assert_selector("span", text: "50%")
  end

  def test_percentage_calculation_handles_zero_max_without_error
    render_inline(Bali::Progress::Component.new(value: 25, max: 0))
    assert_selector("span", text: "0%")
  end
  #

  def test_options_passthrough_passes_custom_classes_to_wrapper
    render_inline(Bali::Progress::Component.new(value: 50, class: "my-custom"))
    assert_selector("div.my-custom")
  end

  def test_options_passthrough_passes_data_attributes_to_wrapper
    render_inline(Bali::Progress::Component.new(value: 50, data: { testid: "progress-bar" }))
    assert_selector('div[data-testid="progress-bar"]')
  end

  def test_options_passthrough_passes_id_to_wrapper
    render_inline(Bali::Progress::Component.new(value: 50, id: "upload-progress"))
    assert_selector("div#upload-progress")
  end
end
