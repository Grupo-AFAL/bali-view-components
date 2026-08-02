# frozen_string_literal: true

require "test_helper"

class BaliImageFieldComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::ImageField::Component.new(**@options)
  end

  def test_default_rendering_renders_with_placeholder_image_by_default
    render_inline(component)
    assert_selector("div.image-field-component")
    assert_selector('img[src^="data:image/svg+xml"]')
  end

  # The placeholder used to be `https://placehold.jp/128x128.png`, so rendering
  # this component fired a request at a third party: it leaked the page's
  # Referer, put a stranger's uptime in front of a form field, and left the
  # component broken behind an offline or egress-filtered network.
  #
  # Asserted over the rendered markup rather than on the constant, because the
  # placeholder is emitted a second time — as a hidden `<img>` — whenever there
  # is an input slot, which is the path that kept firing even with a `src:`.
  def test_no_rendering_path_requests_an_external_url
    external = [ {}, { src: "avatar.png" }, { size: :xl } ].filter_map do |options|
      render_inline(Bali::ImageField::Component.new(**options))

      options.inspect if rendered_content.match?(%r{src="https?://})
    end

    assert_empty external,
                 "ImageField still requests an external URL when rendered with: " \
                 "#{external.join(", ")}"
  end

  def test_default_rendering_applies_image_field_controller
    render_inline(component)
    assert_selector('[data-controller="image-field"]')
  end

  def test_default_rendering_applies_output_target_to_displayed_image
    render_inline(component)
    assert_selector('img[data-image-field-target="output"]')
  end

  def test_default_rendering_applies_default_size_class_md
    render_inline(component)
    assert_selector("img.size-32")
  end

  def test_with_custom_src_renders_the_provided_image
    render_inline(Bali::ImageField::Component.new(src: "https://example.com/avatar.png"))
    assert_selector('img[src="https://example.com/avatar.png"]')
  end

  def test_with_custom_src_falls_back_to_placeholder_url_when_src_is_nil
    @options.merge!(placeholder_url: "https://example.com/placeholder.png")
    render_inline(component)
    assert_selector('img[src="https://example.com/placeholder.png"]')
  end

  def test_with_custom_placeholder_url_uses_custom_placeholder
    render_inline(Bali::ImageField::Component.new(placeholder_url: "https://example.com/my-placeholder.png"))
    assert_selector('img[src="https://example.com/my-placeholder.png"]')
  end

  Bali::ImageField::Component::SIZES.each do |size, expected_class|
    define_method("test_sizes_renders_#{size}_with_#{expected_class}") do
      render_inline(Bali::ImageField::Component.new(size: size))
      assert_selector("img.#{expected_class}")
    end
  end

  def test_image_styling_applies_rounded_and_object_cover_classes
    render_inline(component)
    assert_selector("img.rounded-lg.object-cover")
  end

  def test_image_styling_applies_empty_alt_by_default_for_accessibility
    render_inline(component)
    assert_selector('img[alt=""]')
  end

  def test_styling_classes_applies_base_component_classes
    render_inline(component)
    assert_selector(".image-field-component.group.relative.w-fit")
  end

  def test_options_passthrough_passes_extra_options_to_container
    @options.merge!(data: { test: "value" }, id: "my-image-field")
    render_inline(component)
    assert_selector('[data-test="value"][id="my-image-field"]')
  end

  def test_options_passthrough_merges_with_default_controller
    @options.merge!(data: { custom: "attr" })
    render_inline(component)
    assert_selector('[data-controller="image-field"][data-custom="attr"]')
  end

  def test_options_passthrough_allows_custom_classes
    @options.merge!(class: "my-custom-class")
    render_inline(component)
    assert_selector(".image-field-component.my-custom-class")
  end
end

class BaliImageFieldInputComponentTest < ComponentTestCase
  def helper
    @helper ||= TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  def test_basic_rendering_renders_file_input_with_label_container
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector("label.image-input-container")
    assert_selector('input[type="file"]')
  end

  def test_basic_rendering_renders_camera_icon_by_default
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector("label svg", visible: :all)
  end

  def test_basic_rendering_applies_hover_overlay_classes
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector("label.absolute.inset-0.flex.cursor-pointer")
  end

  def test_basic_rendering_hides_the_file_input_visually
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector('input[type="file"].hidden')
  end

  def test_file_formats_accepts_default_formats
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    input = page.find('input[type="file"]')
    assert_equal(".jpg, .jpeg, .png, .webp", input[:accept])
  end

  def test_file_formats_accepts_custom_formats
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar, formats: %i[gif png]))
    end
    input = page.find('input[type="file"]')
    assert_equal(".gif, .png", input[:accept])
  end

  def test_custom_icon_renders_custom_icon
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar, icon_name: "upload"))
    end
    assert_selector("label svg", visible: :all)
  end

  def test_stimulus_data_attributes_adds_input_target
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector('input[data-image-field-target="input"]')
  end

  def test_stimulus_data_attributes_adds_change_action
    helper.form_with(url: "/") do |form|
      render_inline(Bali::ImageField::Input::Component.new(form: form, method: :avatar))
    end
    assert_selector('input[data-action="change->image-field#show"]')
  end
end

class BaliImageFieldWithInputSlotTest < ComponentTestCase
  def helper
    @helper ||= TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  def test_with_input_slot_renders_input_and_placeholder_image
    helper.form_with(url: "/") do |form|
    render_inline(Bali::ImageField::Component.new) do |c|
      c.with_input(form: form, method: :avatar)
    end
    end
    assert_selector('img[data-image-field-target="output"]')
    assert_selector('img[data-image-field-target="placeholder"]')
    assert_selector("label.image-input-container")
  end

  def test_with_input_slot_renders_default_clear_button_using_bali_button
    helper.form_with(url: "/") do |form|
    render_inline(Bali::ImageField::Component.new) do |c|
      c.with_input(form: form, method: :avatar)
    end
    end
    assert_selector(".clear-image-button")
    assert_selector('button.btn[data-action="image-field#clear"]')
    assert_selector("button[aria-label]")
  end

  def test_with_custom_clear_button_renders_custom_clear_button_when_provided
    helper.form_with(url: "/") do |form|
    render_inline(Bali::ImageField::Component.new) do |c|
      c.with_input(form: form, method: :avatar)
    c.with_clear_button do
      '<button class="custom-clear">Clear</button>'.html_safe
    end
    end
    end
    assert_selector(".custom-clear")
    assert_text("Clear")
  end

  def test_without_input_slot_does_not_render_placeholder_input_or_clear_button
    render_inline(Bali::ImageField::Component.new)
    assert_no_selector('img[data-image-field-target="placeholder"]')
    assert_no_selector("label.image-input-container")
    assert_no_selector(".clear-image-button")
  end
end
