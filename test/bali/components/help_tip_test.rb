# frozen_string_literal: true

require "test_helper"

class BaliHelpTipComponentTest < ComponentTestCase
  def test_renders_an_icon_trigger_with_the_text_in_the_balloon
    render_inline(Bali::HelpTip::Component.new("Systematic overview"))

    assert_selector('[data-controller="tooltip"] .trigger span.icon-component svg')
    assert_selector('template[data-tooltip-target="content"]', visible: :all)
    assert_includes(rendered_content, "Systematic overview")
  end

  def test_placement_reaches_the_tooltip
    render_inline(Bali::HelpTip::Component.new("Help", placement: :right))

    assert_selector('[data-tooltip-placement-value="right"]')
  end

  def test_options_pass_through_to_the_tooltip
    render_inline(Bali::HelpTip::Component.new("Help", class: "ml-2", data: { testid: "tip" }))

    assert_selector('.tooltip-component.ml-2[data-testid="tip"]')
  end

  def test_content_block_is_the_balloon_when_no_text_is_given
    render_inline(Bali::HelpTip::Component.new) { "<strong>Rich</strong> help".html_safe }

    assert_includes(rendered_content, "<strong>Rich</strong> help")
  end
end

# #993: the FieldGroupWrapper "?" and a host's "?" are the same component now —
# the wrapper used to build the Tooltip+Icon pair privately, and hosts rewrote
# it (49 times in one app). This pins that a field's `tooltip:` renders
# HelpTip's markup.
class BaliHelpTipFieldGroupTest < FormBuilderTestCase
  def test_field_group_wrapper_renders_its_tooltip_through_help_tip
    html = builder.text_group(:name, label: { tooltip: "The title as released" })

    assert_html(html, 'label [data-controller="tooltip"] span.icon-component')
    assert_includes(html, "The title as released")
  end
end
