# frozen_string_literal: true

require "test_helper"

class BaliLoaderComponentTest < ComponentTestCase
  def test_basic_rendering_renders_loader_with_default_options
    render_inline(Bali::Loader::Component.new)
    assert_selector("div.loader-component")
    assert_selector("span.loading.loading-spinner.loading-lg")
    assert_selector("p", text: "Loading...")
  end

  def test_basic_rendering_renders_loader_with_custom_text
    render_inline(Bali::Loader::Component.new(text: "Cargando"))
    assert_selector("p", text: "Cargando")
  end

  def test_basic_rendering_hides_text_when_hide_text_option_is_true
    render_inline(Bali::Loader::Component.new(hide_text: true))
    assert_no_selector("p")
  end

  def test_basic_rendering_shows_default_text_when_text_is_nil_and_hide_text_is_false
    render_inline(Bali::Loader::Component.new)
    assert_selector("p", text: "Loading...")
  end

  def test_accessibility_adds_role_status_to_the_spinner
    render_inline(Bali::Loader::Component.new)
    assert_selector('span.loading[role="status"]')
  end

  def test_accessibility_adds_aria_label_with_display_text
    render_inline(Bali::Loader::Component.new(text: "Processing..."))
    assert_selector('span.loading[aria-label="Processing..."]')
  end

  def test_accessibility_uses_default_translation_for_aria_label_when_no_text_provided
    render_inline(Bali::Loader::Component.new)
    assert_selector('span.loading[aria-label="Loading..."]')
  end

  def test_types_renders_spinner_type_by_default
    render_inline(Bali::Loader::Component.new)
    assert_selector("span.loading.loading-spinner")
  end
  Bali::Loader::Component::TYPES.each_key do |type|
    define_method("test_types_renders_#{type}_type") do
      render_inline(Bali::Loader::Component.new(type: type, hide_text: true))
      assert_selector("span.loading.loading-#{type}")
    end
  end

  Bali::Loader::Component::SIZES.each_key do |size|
    define_method("test_sizes_renders_#{size}_size") do
      render_inline(Bali::Loader::Component.new(size: size, hide_text: true))
      assert_selector("span.loading.loading-#{size}")
    end
  end

  Bali::Loader::Component::COLORS.each do |color, css_class|
    define_method("test_colors_renders_#{color}_color_on_spinner") do
      render_inline(Bali::Loader::Component.new(color: color, hide_text: true))
      assert_selector("span.loading.#{css_class}")
    end
  end

  # The text is on the page and takes the soft mix; test/bali/theme_contrast_test.rb measures it.
  Bali::Loader::Component::COLORS.except(:neutral).each_key do |color|
    define_method("test_text_colors_renders_#{color}_text_in_its_soft_mix") do
      render_inline(Bali::Loader::Component.new(color: color))
      assert_selector("p.text-soft-#{color}")
    end
  end

  # `neutral` has no mix. The text is the spinner's sibling, not its child: without a class of
  # its own it would take the colour of whatever the loader sits in.
  def test_neutral_text_stays_on_base_content
    render_inline(Bali::Loader::Component.new(color: :neutral))
    assert_selector("p.text-base-content")
  end

  def test_the_spinner_keeps_the_colour_and_the_text_takes_the_soft_one
    render_inline(Bali::Loader::Component.new(color: :warning))

    assert_selector("span.loading.text-warning + p.text-soft-warning")
  end

  def test_options_passthrough_accepts_custom_classes_on_container
    render_inline(Bali::Loader::Component.new(class: "my-custom-class"))
    assert_selector("div.loader-component.my-custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Loader::Component.new(data: { testid: "loader" }))
    assert_selector('div.loader-component[data-testid="loader"]')
  end

  def test_options_passthrough_accepts_custom_id
    render_inline(Bali::Loader::Component.new(id: "my-loader"))
    assert_selector("div#my-loader.loader-component")
  end
end
