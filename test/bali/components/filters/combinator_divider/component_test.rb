# frozen_string_literal: true

require "test_helper"

# El divisor AND/OR entre grupos de filtros no tenía test propio (#1028). Fija
# el estado activo (clases Y aria-pressed: un lector de pantalla no distingue
# btn-primary de btn-outline), el nombre accesible del grupo y el hidden `q[m]`
# que persiste la elección.
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
