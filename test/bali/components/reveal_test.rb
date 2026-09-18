# frozen_string_literal: true

require "test_helper"

class BaliRevealComponentTest < ComponentTestCase
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
    assert_selector('button.reveal-trigger[type="button"][data-action="click->reveal#toggle"]')
    assert_selector("div.reveal-title", text: "Click here")
    assert_selector(".icon-component")
  end

  def test_trigger_is_a_button_pointing_at_the_content_it_controls
    render_inline(@component) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    controls = page.find("button.reveal-trigger")["aria-controls"]
    refute_nil(controls)
    assert_selector("div.reveal-content##{controls}")
  end

  def test_trigger_reuses_the_component_id_for_the_content_id
    render_inline(Bali::Reveal::Component.new(id: "my-reveal")) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    assert_selector('button.reveal-trigger[aria-controls="my-reveal-content"]')
    assert_selector("div.reveal-content#my-reveal-content")
  end

  def test_trigger_is_a_stimulus_target_so_the_controller_can_sync_aria_expanded
    render_inline(@component) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    assert_selector('button.reveal-trigger[data-reveal-target="trigger"]')
  end

  def test_trigger_reports_collapsed_when_the_component_is_closed
    render_inline(@component) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    assert_selector('button.reveal-trigger[aria-expanded="false"]')
  end

  def test_trigger_reports_expanded_when_the_component_is_opened
    render_inline(Bali::Reveal::Component.new(opened: true)) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    assert_selector('button.reveal-trigger[aria-expanded="true"]')
  end

  def test_trigger_renders_border_at_bottom_by_default
    render_inline(@component) do |c|
      c.with_trigger do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    assert_selector("button.reveal-trigger.border-b")
  end

  def test_trigger_hides_border_when_show_border_is_false
    render_inline(@component) do |c|
      c.with_trigger(show_border: false) do |trigger|
        trigger.with_title { "Click here" }
      end
    end
    assert_no_selector("button.reveal-trigger.border-b")
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

  # #1148 — the trigger's default spacing lives in reveal/index.css, inside
  # @layer components, and no longer as utilities in this attribute. Written
  # here, `pb-6`/`mb-6` land in @layer utilities alongside whatever the host
  # writes, where only source order breaks the tie — and Tailwind emits each
  # spacing family in ascending order, so Bali's 6 always sorted after the
  # host's 0. See app/components/bali/reveal/index.css for the measurement.
  def test_trigger_spacing_is_not_an_inline_utility
    render_inline(@component) do |c|
      c.with_trigger { |trigger| trigger.with_title { "Click here" } }
    end
    refute_selector("button.reveal-trigger.pb-6")
    refute_selector("button.reveal-trigger.mb-6")
  end

  def test_trigger_spacing_from_the_host_arrives_without_a_competing_default
    render_inline(@component) do |c|
      c.with_trigger(class: "pb-0 mb-0") { |trigger| trigger.with_title { "Click here" } }
    end
    assert_selector("button.reveal-trigger.pb-0.mb-0")
    refute_selector("button.reveal-trigger.pb-6")
    refute_selector("button.reveal-trigger.mb-6")
  end

  # Same defect, same fix: `mb-8` on the content was an inline utility too.
  def test_content_spacing_is_not_an_inline_utility
    render_inline(@component) { "Hidden content" }
    assert_selector("div.reveal-content")
    refute_selector("div.reveal-content.mb-8")
  end

  # Moving `mb-8` into the sheet only helps if something can reach that element:
  # the content box takes no slot options, so it gets a `content_class:` hook.
  def test_content_accepts_a_host_class_that_beats_the_default_gap
    render_inline(Bali::Reveal::Component.new(content_class: "mb-0")) { "Hidden content" }
    assert_selector("div.reveal-content.mb-0", text: "Hidden content")
    assert_no_selector("[content_class]")
  end

  def test_constants_has_frozen_base_classes
    assert(Bali::Reveal::Component::BASE_CLASSES.frozen?)
  end

  def test_constants_has_frozen_opened_class
    assert(Bali::Reveal::Component::OPENED_CLASS.frozen?)
  end
end
