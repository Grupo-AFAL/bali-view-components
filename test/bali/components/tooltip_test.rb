# frozen_string_literal: true

require "test_helper"

class BaliTooltipComponentTest < ComponentTestCase
  def test_constants_has_frozen_positions_hash
    assert(Bali::Tooltip::Component::POSITIONS.frozen?)
  end

  def test_constants_defines_all_four_positions
    assert_equal(%i[top bottom left right].sort, Bali::Tooltip::Component::POSITIONS.keys.sort)
  end

  def test_constants_has_controller_constant
    assert_equal("tooltip", Bali::Tooltip::Component::CONTROLLER)
  end
  def test_basic_rendering_renders_tooltip_with_trigger_content
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.span "?" }
      c.tag.p "Tooltip content"
    end
    assert_selector(".tooltip-component")
    assert_selector(".trigger", text: "?")
  end

  def test_basic_rendering_includes_stimulus_controller_data_attributes
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-controller="tooltip"]')
    assert_selector('[data-tooltip-target="trigger"]')
    assert_selector('template[data-tooltip-target="content"]', visible: false)
  end

  def test_basic_rendering_renders_inline_block_container
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector(".inline-block")
  end
  Bali::Tooltip::Component::POSITIONS.each_key do |placement|
    define_method("test_placement_sets_#{placement}_placement") do
      render_inline(Bali::Tooltip::Component.new(placement: placement)) do |c|
        c.with_trigger { c.tag.span "Hover" }
      end
      assert_selector("[data-tooltip-placement-value=\"#{placement}\"]")
    end
  end

  def test_defaults_to_top_placement
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-tooltip-placement-value="top"]')
  end

  def test_handles_invalid_placement_gracefully
    render_inline(Bali::Tooltip::Component.new(placement: :invalid)) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-tooltip-placement-value="top"]')
  end

  def test_custom_trigger_events_sets_custom_trigger_event
    render_inline(Bali::Tooltip::Component.new(trigger_event: "click")) do |c|
      c.with_trigger { c.tag.span "Click me" }
    end
    assert_selector('[data-tooltip-trigger-value="click"]')
  end

  def test_custom_trigger_events_defaults_to_mouseenter_focus
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-tooltip-trigger-value="mouseenter focus"]')
  end
  def test_options_passthrough_accepts_custom_class_via_options
    render_inline(Bali::Tooltip::Component.new(class: "help-tip")) do |c|
      c.with_trigger { c.tag.span "?" }
    end
    assert_selector(".tooltip-component.help-tip")
  end

  def test_options_passthrough_passes_through_data_attributes
    render_inline(Bali::Tooltip::Component.new(data: { testid: "my-tooltip" })) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-testid="my-tooltip"]')
  end

  def test_options_passthrough_merges_data_attributes_with_stimulus_data
    render_inline(Bali::Tooltip::Component.new(data: { custom: "value" })) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('[data-controller="tooltip"][data-custom="value"]')
  end

  def test_options_passthrough_passes_through_arbitrary_html_attributes
    render_inline(Bali::Tooltip::Component.new(id: "tooltip-1", role: "tooltip")) do |c|
      c.with_trigger { c.tag.span "Hover" }
    end
    assert_selector('#tooltip-1[role="tooltip"]')
  end
  def test_trigger_slot_renders_custom_trigger_content
    render_inline(Bali::Tooltip::Component.new) do |c|
      c.with_trigger { c.tag.button "Click me", class: "btn btn-primary" }
      c.tag.p "Tooltip text"
    end
    assert_selector(".trigger button.btn.btn-primary", text: "Click me")
  end
end
