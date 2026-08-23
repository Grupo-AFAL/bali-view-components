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
# Every family with a control resolves through the one discriminator,
# `HtmlUtils#size_variant`, and differs only in the map it hands it — which is
# what makes the sweep below a sweep and not a list of special cases.
#
# One carve-out (#1076): the block editor families have no input the attribute
# could reach, so their `size:` is the component's own API — the text scale,
# resolved by `BlockEditor::Component#size_class`, not by `size_variant`. There
# the Integer/String bullet above does not apply: an Integer, or a String that
# does not name a scale, raises the component's ArgumentError instead of
# passing through, and a String like `"sm"` reads as the scale.
class BaliFormBuilderSizeOptionTest < FormBuilderTestCase
  INPUT_VARIANTS = {
    xs: "input-xs", sm: "input-sm", md: "input-md", lg: "input-lg", xl: "input-xl"
  }.freeze

  # Every group helper whose control takes a density, with the class `size: :sm`
  # has to put on it. The selector is the control itself, so a class that lands
  # on a wrapper instead — the mistake that is invisible in a string match —
  # fails here.
  #
  # Where the option is written is part of each family's contract too: the four
  # families with a second hash read it from either one (see
  # `select_size_variant`), and `radio_group` only ever reads `html:`, the same
  # place its `required:` lives.
  CARRIES = {
    "text_group" => [ ->(b, o) { b.text_group(:name, **o) }, "input.input-sm" ],
    "email_group" => [ ->(b, o) { b.email_group(:name, **o) }, "input.input-sm" ],
    "url_group" => [ ->(b, o) { b.url_group(:name, **o) }, "input.input-sm" ],
    "password_group" => [ ->(b, o) { b.password_group(:name, **o) }, "input.input-sm" ],
    "number_group" => [ ->(b, o) { b.number_group(:budget, **o) }, "input.input-sm" ],
    "month_group" => [ ->(b, o) { b.month_group(:release_date, **o) }, "input.input-sm" ],
    "date_group" => [ ->(b, o) { b.date_group(:release_date, **o) }, "input.input-sm" ],
    "datetime_group" => [ ->(b, o) { b.datetime_group(:release_date, **o) }, "input.input-sm" ],
    "time_group" => [ ->(b, o) { b.time_group(:duration, **o) }, "input.input-sm" ],
    "search_group" => [ ->(b, o) { b.search_group(:name, **o) }, "input.input-sm" ],
    "currency_group" => [ ->(b, o) { b.currency_group(:budget, **o) }, "input.input-sm" ],
    "percentage_group" => [ ->(b, o) { b.percentage_group(:budget, **o) }, "input.input-sm" ],
    "numeric_group" => [ ->(b, o) { b.numeric_group(:budget, **o) }, "input.input-sm" ],
    "step_number_group" => [ ->(b, o) { b.step_number_group(:duration, **o) }, "input.input-sm" ],
    "text_area_group" => [ ->(b, o) { b.text_area_group(:synopsis, **o) }, "textarea.textarea-sm" ],
    "select_group" => [ ->(b, o) { b.select_group(:status, [], **o) }, "select.select-sm" ],
    "time_zone_select_group" => [
      ->(b, o) { b.time_zone_select_group(:name, **o) }, "select.select-sm"
    ],
    # SlimSelect draws its own widget over a `<select>` the CSS clips to 1x1, so
    # its density is the wrapper's — the only element with a size to change.
    "slim_select_group" => [
      ->(b, o) { b.slim_select_group(:status, [], **o) }, "div.slim-select.slim-select-sm"
    ],
    "range_group" => [ ->(b, o) { b.range_group(:rating, **o) }, "input.range-sm" ],
    # The block editor's density is its own API — the text scale — not the
    # `<input>` attribute the other widget families drop (#1076). The class
    # lands on the component wrapper, the only element with a size to change.
    "block_editor_group" => [
      ->(b, o) { b.block_editor_group(:synopsis, **o) },
      "div.block-editor-component.block-editor-size-sm"
    ],
    "rich_text_group" => [
      ->(b, o) { b.rich_text_group(:synopsis, **o) },
      "div.block-editor-component.block-editor-size-sm"
    ],
    "boolean_group" => [ ->(b, o) { b.boolean_group(:indie, **o) }, "input.checkbox-sm" ],
    "switch_group" => [ ->(b, o) { b.switch_group(:indie, **o) }, "input.toggle-sm" ],
    "radio_group" => [
      ->(b, o) { b.radio_group(:status, [ %w[One 1] ], html: o) }, "input.radio-sm"
    ],
    # Its native input is hidden and the button is the whole visible control, so
    # the density is the button's. `file-input-*` never applies here: this family
    # does not render a daisyUI file input.
    "file_group" => [ ->(b, o) { b.file_group(:name, **o) }, "span.btn.btn-sm" ],
    "submit_group" => [ ->(b, o) { b.submit_group("Save", **o) }, "button.btn.btn-sm" ]
  }.freeze

  # Everything whose control is a widget over a hidden field: there is no daisyUI
  # component underneath to give a density to, and the editors size themselves
  # from their content. Named here rather than left out, so the coverage check
  # below stays a check — and asserted to emit no `size` attribute either, since
  # forwarding it would put `size` on a `<div>` or a `<trix-editor>`.
  # (The block editor moved to CARRIES when its `size:` became the text scale,
  # #1076; the Trix editor still has no density to give the option to.)
  IGNORES = {
    "rich_text_area_group" => ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    # Togglers and grouped radios: `radios:` is the container hash, not the
    # radio's own attributes, so there is no single control this could reach.
    "radio_buttons_group" => lambda { |b, o|
      b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o)
    }
  }.freeze

  # `dynamic_fields_group` renders a button and a container for nested records,
  # never a control of its own, and it needs a real association to render at all.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  def test_every_group_helper_is_covered_by_this_sweep
    swept = CARRIES.keys + IGNORES.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `size:` expectation, so nothing says whether the " \
                 "option is a density or an attribute there: #{uncovered.sort.inspect}. " \
                 "Add each to CARRIES or IGNORES."
  end

  def test_a_symbol_size_becomes_the_daisyui_variant_of_every_family_that_has_one
    missing = CARRIES.filter_map do |name, (render, selector)|
      html = render.call(builder, { size: :sm })
      "#{name}: expected #{selector}" if Nokogiri::HTML5.fragment(html.to_s).css(selector).empty?
    end

    assert_empty missing, "`size: :sm` did not reach the control:\n#{missing.join("\n")}"
  end

  # The other half, and the reason the option needed a rule at all: the variant
  # is a class, so the attribute of the same name must not be emitted next to it.
  def test_a_symbol_size_never_reaches_the_markup_as_an_attribute
    emitted = CARRIES.filter_map do |name, (render, _selector)|
      elements = size_attribute_elements(render.call(builder, { size: :sm }))
      "#{name}: #{elements.inspect}" if elements.any?
    end

    assert_empty emitted, "the variant leaked out as a `size` attribute:\n#{emitted.join("\n")}"
  end

  def test_an_unknown_symbol_raises_in_every_family_that_reads_the_option
    silent = CARRIES.reject do |_name, (render, _selector)|
      assert_raises(ArgumentError) { render.call(builder, { size: :tiny }) }
    end

    assert_empty silent.keys
  end

  def test_the_families_over_a_hidden_field_do_not_read_the_option_at_all
    emitted = IGNORES.filter_map do |name, render|
      elements = size_attribute_elements(render.call(builder, { size: :sm }))
      "#{name}: #{elements.inspect}" if elements.any?
    end

    assert_empty emitted,
                 "`size:` reached an element that has no density and no size attribute:\n" \
                 "#{emitted.join("\n")}"
  end

  def test_every_input_variant_resolves
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

  # A `<select>` is the case that makes the discrimination worth the trouble:
  # `size` there is the number of visible rows, and a select with one is a
  # listbox rather than a dropdown.
  def test_a_select_keeps_the_integer_attribute
    html = builder.select_group(:status, [ %w[One 1] ], html: { size: 4 })

    assert_html html, "select[size='4']"
    refute_html html, "select[class*='select-4']"
  end

  # Rails' `select_content_tag` copies `:size` out of the select's own options
  # and onto the element, so the variant has to be taken out of both hashes —
  # this is the spelling that used to emit `<select size="sm">`.
  def test_a_select_reads_the_variant_from_either_hash
    assert_html builder.select_group(:status, [], size: :lg), "select.select-lg"
    assert_html builder.select_group(:status, [], html: { size: :lg }), "select.select-lg"
    refute_html builder.select_group(:status, [], size: :lg), "select[size]"
    refute_html builder.select_group(:status, [], html: { size: :lg }), "select[size]"
  end

  def test_slim_select_reads_the_variant_from_either_hash_and_keeps_it_off_the_select
    [ { size: :sm }, { html: { size: :sm } } ].each do |options|
      html = builder.slim_select_group(:status, [ %w[One 1] ], **options)

      assert_html html, "div.slim-select.slim-select-sm"
      refute_html html, "select[size]"
    end
  end

  # SlimSelect has CSS for exactly one density, so the other symbols raise rather
  # than resolving to a class no stylesheet defines. The message says which.
  def test_slim_select_raises_for_a_density_it_has_no_css_for
    error = assert_raises(ArgumentError) do
      builder.slim_select_group(:status, [], size: :lg)
    end

    assert_includes error.message, ":sm"
  end

  # Rails' `text_area` reads `size` as "colsxrows", and that is a String — the
  # very shape the discriminator lets through untouched.
  def test_a_textarea_keeps_rails_cols_by_rows_string
    html = builder.text_area_field(:synopsis, size: "20x40")

    assert_html html, "textarea[cols='20'][rows='40']"
    refute_html html, "textarea[size]"
  end

  # With `alt_input:` the input the user sees is the one flatpickr builds from
  # `data-datepicker-alt-input-class-value`, not the one in the markup.
  def test_the_datepicker_alt_input_carries_the_variant
    html = builder.date_group(:release_date, alt_input: true, size: :sm)
    value = Nokogiri::HTML5.fragment(html.to_s)
                           .css("[data-datepicker-alt-input-class-value]")
                           .first["data-datepicker-alt-input-class-value"]

    assert_includes value, "input-sm"
  end

  # The file CTA is a button that has always been `btn-sm`; asking for a density
  # replaces that one class rather than adding a second to fight with it.
  def test_the_file_cta_keeps_its_default_size_and_swaps_it_when_asked
    assert_html builder.file_group(:name), "span.btn.btn-sm"
    assert_html builder.file_group(:name, size: :xs), "span.btn.btn-xs"
    refute_html builder.file_group(:name, size: :xs), "span.btn-sm"
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

  def size_attribute_elements(html)
    Nokogiri::HTML5.fragment(html.to_s).css("[size]").map(&:name)
  end

  def live_group_helpers
    deprecated = Bali::FormBuilder::DeprecatedNames.instance_methods.map(&:to_s)

    Bali::FormBuilder.instance_methods.map(&:to_s).grep(/_group\z/) - deprecated
  end

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
