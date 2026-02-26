# frozen_string_literal: true

require "test_helper"

class Bali_Reveal_ComponentTest < ComponentTestCase
  def setup
    @component = Bali::Reveal::Component.new
  end

  def test_rendering_renders_with_hidden_content
    render_inline(@component)
    assert_selector("div.reveal-component")
    assert_no_selector("div.reveal-component.is-revealed")
  end

  def test_rendering_renders_with_opened_content
    render_inline(Bali::Reveal::Component.new(opened: true))
    assert_selector("div.reveal-component")
    assert_selector("div.reveal-component.is-revealed")
  end

  def test_rendering_renders_reveal_content_container
    render_inline(@component) { "Hidden content" }
    assert_selector("div.reveal-content.hidden", text: "Hidden content")
  end

  def test_rendering_includes_reveal_stimulus_controller
    render_inline(@component)
    assert_selector('div[data-controller~="reveal"]')
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Reveal::Component.new(class: "custom-class"))
    assert_selector("div.reveal-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Reveal::Component.new(data: { testid: "reveal-test" }))
    assert_selector('div[data-testid="reveal-test"]')
  end

  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::Reveal::Component.new(id: "my-reveal"))
    assert_selector("div#my-reveal.reveal-component")
  end

  def test_trigger_renders_trigger_with_title
    render_inline(@component) do |c|
      c.with_trigger do |trigger|
        trigger.with_title do
          '<div class="reveal-title">Click here</div>'.html_safe
        end
      end
    end
    assert_selector('div.reveal-trigger[data-action="click->reveal#toggle"]')
    assert_selector("div.reveal-title", text: "Click here")
    assert_selector(".icon-component")
  end

  def test_trigger_renders_border_at_bottom_by_default
    render_inline(@component) do |c|
      c.with_trigger do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    assert_selector("div.reveal-trigger.border-b")
  end

  def test_trigger_hides_border_when_show_border_is_false
    render_inline(@component) do |c|
      c.with_trigger(show_border: false) do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    assert_no_selector("div.reveal-trigger.border-b")
  end

  def test_trigger_accepts_custom_icon_class
    render_inline(@component) do |c|
      c.with_trigger(icon_class: "text-primary") do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    assert_selector(".trigger-icon.text-primary")
  end

  def test_trigger_rotates_icon_when_revealed
    render_inline(@component) do |c|
      c.with_trigger do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    # Icon starts rotated and unrotates when parent has is-revealed
    assert_selector(".trigger-icon.rotate-\\[270deg\\]")
  end

  def test_constants_has_frozen_base_classes
    assert(Bali::Reveal::Component::BASE_CLASSES.frozen?)
  end

  def test_constants_has_frozen_opened_class
    assert(Bali::Reveal::Component::OPENED_CLASS.frozen?)
  end
end
