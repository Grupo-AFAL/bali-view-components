# frozen_string_literal: true

require "test_helper"

# `size:` is the one option with two legitimate meanings on a form control
# (#723, D723-3): daisyUI's density variant and the HTML attribute of the same
# name — width in characters on an `<input>`, visible rows on a `<select>`.
# The contract this file freezes:
#
#   - a Symbol out of the family's map is the variant: the class joins the
#     control's base classes and the attribute is NOT emitted;
#   - an Integer — or a String, which is what `size: "4"` always meant — keeps
#     meaning the attribute and passes through untouched;
#   - a Symbol the map does not know raises, instead of leaking `size="tiny"`
#     into the markup. Same contract ButtonTaxonomy enforces for the submit
#     button, which is the family that already had `size:` before this PR.
#
# This is the foundation: the text-input families resolve through
# `input_base_class`, and the per-family maps (`select-*`, `textarea-*`,
# `file-input-*`, `range-*`) build on `size_variant` in the follow-up PR.
class BaliFormBuilderSizeOptionTest < FormBuilderTestCase
  INPUT_VARIANTS = {
    xs: "input-xs", sm: "input-sm", md: "input-md", lg: "input-lg", xl: "input-xl"
  }.freeze

  def test_a_symbol_is_the_daisyui_variant_and_never_the_attribute
    INPUT_VARIANTS.each do |symbol, css_class|
      html = builder.text_field(:name, size: symbol)

      assert_html html, "input.#{css_class}"
      refute_html html, "input[size]"
    end
  end

  def test_the_variant_travels_through_the_group_too
    html = builder.text_group(:name, size: :sm)

    assert_html html, "fieldset input.input-sm"
    refute_html html, "input[size]"
  end

  def test_an_integer_keeps_meaning_the_html_attribute
    html = builder.text_field(:name, size: 4)

    assert_html html, "input[size='4']"
    refute_html html, "input[class*='input-4']"
    INPUT_VARIANTS.each_value { |css_class| refute_html html, "input.#{css_class}" }
  end

  # The subtle case out of the #723 analysis: a host passing the attribute as a
  # String must not change meaning when the Symbol variant exists.
  def test_a_string_keeps_meaning_the_html_attribute
    html = builder.text_field(:name, size: "4")

    assert_html html, "input[size='4']"
  end

  def test_an_unknown_symbol_raises_instead_of_leaking_into_the_markup
    error = assert_raises(ArgumentError) { builder.text_field(:name, size: :tiny) }

    assert_includes error.message, ":tiny"
    assert_includes error.message, ":xs"
  end

  def test_the_variant_joins_the_addon_base_class
    html = builder.currency_field(:budget, size: :xl)

    assert_html html, ".join input.join-item.input-xl"
    refute_html html, "input[size]"
  end

  # D723-3 includes the submit pair. It resolves through ButtonTaxonomy, which
  # already discriminates and raises on unknowns — asserted here so the two
  # mechanisms cannot drift apart.
  def test_submit_field_and_group_map_the_same_symbols_to_btn_classes
    assert_html builder.submit_field("Save", size: :sm), "button.btn.btn-sm"
    assert_html builder.submit_group("Save", size: :sm), "button.btn.btn-sm"
    assert_raises(ArgumentError) { builder.submit_field("Save", size: :tiny) }
  end

  private

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
