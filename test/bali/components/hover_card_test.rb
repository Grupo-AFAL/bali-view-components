# frozen_string_literal: true

require "test_helper"

class BaliHoverCardComponentTest < ComponentTestCase
  def setup
    @component = Bali::HoverCard::Component.new
  end


  def test_constants_has_frozen_placements_constant
    assert(Bali::HoverCard::Component::PLACEMENTS.frozen?)
    assert_includes(Bali::HoverCard::Component::PLACEMENTS, "auto")
    assert_includes(Bali::HoverCard::Component::PLACEMENTS, "top")
    assert_includes(Bali::HoverCard::Component::PLACEMENTS, "bottom")
    assert_includes(Bali::HoverCard::Component::PLACEMENTS, "left")
    assert_includes(Bali::HoverCard::Component::PLACEMENTS, "right")
  end


  def test_constants_has_frozen_triggers_constant
    assert(Bali::HoverCard::Component::TRIGGERS.frozen?)
    assert_equal("mouseenter focus", Bali::HoverCard::Component::TRIGGERS[:hover])
    assert_equal("click", Bali::HoverCard::Component::TRIGGERS[:click])
  end


  def test_constants_has_default_z_index_constant
    assert_equal(9999, Bali::HoverCard::Component::DEFAULT_Z_INDEX)
  end


  def test_rendering_with_template_content_renders_wrapper_with_hover_card_component_class
    render_inline(@component) do
      "<p>Content</p>".html_safe
    end
    assert_selector("div.hover-card-component")
  end


  def test_rendering_with_template_content_includes_template_target_for_content
    render_inline(@component) do
      "<p>Content</p>".html_safe
    end
    assert_includes(rendered_content, 'data-hovercard-target="template"')
    assert_includes(rendered_content, "Content")
  end


  def test_rendering_with_template_content_wraps_content_with_hover_card_content_class_by_default
    render_inline(@component) do
      "<p>Content</p>".html_safe
    end
    assert_includes(rendered_content, 'class="hover-card-content"')
  end


  def test_rendering_with_trigger_slot_renders_trigger_with_data_attribute
    render_inline(@component) do |c|
      c.with_trigger { "Trigger text" }
    end
    assert_selector('[data-hovercard-target="trigger"]', text: "Trigger text")
  end


  def test_hover_url_parameter_sets_url_value_for_async_loading
    render_inline(Bali::HoverCard::Component.new(hover_url: "/content-endpoint"))
    assert_includes(rendered_content, 'data-hovercard-url-value="/content-endpoint"')
  end


  def test_hover_url_parameter_does_not_render_template_when_using_hover_url
    render_inline(Bali::HoverCard::Component.new(hover_url: "/content-endpoint"))
    refute_includes(rendered_content, 'data-hovercard-target="template"')
  end


  def test_placement_parameter_with_valid_placement_applies_placement_value
    render_inline(Bali::HoverCard::Component.new(placement: "top-start"))
    assert_includes(rendered_content, 'data-hovercard-placement-value="top-start"')
  end


  def test_placement_parameter_with_invalid_placement_falls_back_to_auto
    render_inline(Bali::HoverCard::Component.new(placement: "invalid"))
    assert_includes(rendered_content, 'data-hovercard-placement-value="auto"')
  end

  Bali::HoverCard::Component::PLACEMENTS.each do |placement|
    define_method("test_placement_parameter_accepts_#{placement.gsub(/[^a-z0-9_]/, '_')}_placement") do
      render_inline(Bali::HoverCard::Component.new(placement: placement))
      assert_includes(rendered_content, "data-hovercard-placement-value=\"#{placement}\"")
    end
  end


  def test_open_on_click_parameter_when_false_default_uses_hover_trigger
    render_inline(@component)
    assert_includes(rendered_content, 'data-hovercard-trigger-value="mouseenter focus"')
  end


  def test_open_on_click_parameter_when_true_uses_click_trigger
    render_inline(Bali::HoverCard::Component.new(open_on_click: true))
    assert_includes(rendered_content, 'data-hovercard-trigger-value="click"')
  end


  def test_content_padding_parameter_when_true_default_wraps_content_with_padding_class
    render_inline(@component) do
      "<p>Content</p>".html_safe
    end
    assert_includes(rendered_content, 'class="hover-card-content"')
  end


  def test_content_padding_parameter_when_true_default_sets_content_padding_value_to_true
    render_inline(@component)
    assert_includes(rendered_content, 'data-hovercard-content-padding-value="true"')
  end


  def test_content_padding_parameter_when_false_does_not_wrap_content_with_padding_class
    render_inline(Bali::HoverCard::Component.new(content_padding: false)) do
      "<p>Content</p>".html_safe
    end
    assert_no_selector(".hover-card-content")
  end


  def test_content_padding_parameter_when_false_sets_content_padding_value_to_false
    render_inline(Bali::HoverCard::Component.new(content_padding: false))
    assert_includes(rendered_content, 'data-hovercard-content-padding-value="false"')
  end


  def test_arrow_parameter_when_true_default_sets_arrow_value_to_true
    render_inline(@component)
    assert_includes(rendered_content, 'data-hovercard-arrow-value="true"')
  end


  def test_arrow_parameter_when_false_sets_arrow_value_to_false
    render_inline(Bali::HoverCard::Component.new(arrow: false))
    assert_includes(rendered_content, 'data-hovercard-arrow-value="false"')
  end


  def test_z_index_parameter_with_default_value_uses_default_z_index
    render_inline(@component)
    assert_includes(rendered_content, 'data-hovercard-z-index-value="9999"')
  end


  def test_z_index_parameter_with_custom_value_applies_custom_z_index
    render_inline(Bali::HoverCard::Component.new(z_index: 10_001))
    assert_includes(rendered_content, 'data-hovercard-z-index-value="10001"')
  end


  def test_append_to_parameter_with_default_value_appends_to_body
    render_inline(@component)
    assert_includes(rendered_content, 'data-hovercard-append-to-value="body"')
  end


  def test_append_to_parameter_with_parent_appends_to_parent
    render_inline(Bali::HoverCard::Component.new(append_to: "parent"))
    assert_includes(rendered_content, 'data-hovercard-append-to-value="parent"')
  end


  def test_append_to_parameter_with_css_selector_appends_to_selector
    render_inline(Bali::HoverCard::Component.new(append_to: "#my-container"))
    assert_includes(rendered_content, 'data-hovercard-append-to-value="#my-container"')
  end


  def test_options_passthrough_merges_custom_classes
    render_inline(Bali::HoverCard::Component.new(class: "custom-class", id: "my-hovercard"))
    assert_selector("div.hover-card-component.custom-class")
  end


  def test_options_passthrough_passes_through_other_html_attributes
    render_inline(Bali::HoverCard::Component.new(class: "custom-class", id: "my-hovercard"))
    assert_selector("div#my-hovercard")
  end


  def test_options_passthrough_with_custom_data_attributes_merges_custom_data_attributes_with_stimulus_data
    render_inline(Bali::HoverCard::Component.new(data: { testid: "my-test", custom: "value" }))
    assert_includes(rendered_content, 'data-testid="my-test"')
    assert_includes(rendered_content, 'data-custom="value"')
    assert_includes(rendered_content, 'data-controller="hovercard"')
  end


  def test_stimulus_controller_has_hovercard_controller
    render_inline(@component)
    assert_includes(rendered_content, 'data-controller="hovercard"')
  end
end
