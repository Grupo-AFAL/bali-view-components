# frozen_string_literal: true

require "test_helper"

# The AND/OR divider between filter groups had no test of its own (#1028). It pins the active state
# (classes AND aria-pressed: a screen reader cannot tell btn-primary from btn-outline), the group's
# accessible name and the hidden `q[m]` that persists the choice.
class BaliFiltersCombinatorDividerComponentTest < ComponentTestCase
  def test_renders_both_buttons_with_the_and_state_active
    render_inline(Bali::Filters::CombinatorDivider::Component.new(combinator: "and"))

    assert_selector("button[data-combinator='and'].btn-primary[aria-pressed='true']")
    assert_selector("button[data-combinator='or'].btn-outline[aria-pressed='false']")
  end

  def test_renders_the_or_state_active
    render_inline(Bali::Filters::CombinatorDivider::Component.new(combinator: "or"))

    assert_selector("button[data-combinator='or'].btn-primary[aria-pressed='true']")
    assert_selector("button[data-combinator='and'].btn-outline[aria-pressed='false']")
  end

  def test_the_toggle_is_a_named_group
    render_inline(Bali::Filters::CombinatorDivider::Component.new(combinator: "and"))

    assert_selector("[role='group'][aria-label='#{I18n.t('bali_view.filters.combinator_toggle')}']")
  end

  def test_carries_the_hidden_field_that_persists_the_choice
    render_inline(Bali::Filters::CombinatorDivider::Component.new(combinator: "or"))

    assert_selector("input[type='hidden'][name='q[m]'][value='or']", visible: :all)
  end
end
