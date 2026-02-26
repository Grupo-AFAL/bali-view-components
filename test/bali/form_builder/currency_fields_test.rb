# frozen_string_literal: true

require "test_helper"

class BaliFormBuilderCurrencyFieldsTest < FormBuilderTestCase
  def setup
    @currency_field_group = builder.currency_field_group(:budget)
    @currency_field_group_custom = builder.currency_field_group(:budget, symbol: "€")
  end

  def test_currency_field_group_renders_a_label_and_input_within_a_wrapper
    assert_html(@currency_field_group, "fieldset#field-budget.fieldset")
  end

  def test_currency_field_group_renders_a_label
    assert_html(@currency_field_group, "legend.fieldset-legend", text: "Budget")
  end

  def test_currency_field_group_renders_a_currency_sign_within_a_join_wrapper
    assert_html(@currency_field_group, "div.join", text: "$")
  end

  def test_currency_field_group_renders_an_input
    assert_html(@currency_field_group, 'input#movie_budget[name="movie[budget]"][type="text"][step="0.01"][placeholder="0"]')
  end

  def test_currency_field_group_uses_default_symbol
    assert_html(@currency_field_group, "span.btn.btn-disabled.join-item", text: "$")
  end

  def test_currency_field_group_with_custom_symbol_renders_the_custom_currency_symbol
    assert_html(@currency_field_group_custom, "span.btn.btn-disabled.join-item", text: "€")
  end

  def test_currency_field_group_with_custom_symbol_does_not_render_the_default_symbol
    refute_html(@currency_field_group_custom, "span.btn.btn-disabled.join-item", text: "$")
  end
end
