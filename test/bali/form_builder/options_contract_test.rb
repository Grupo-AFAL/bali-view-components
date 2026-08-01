# frozen_string_literal: true

require "test_helper"

# The contract every FormBuilder helper owes its caller:
#
#   1. no option Bali consumes itself may reach the DOM as an HTML attribute;
#   2. the options hash the caller passed in comes back untouched.
#
# Both are asserted by sweeping every helper, not by sampling one: the point of
# a single extraction list is that no helper can quietly opt out of it.
class BaliFormBuilderOptionsContractTest < FormBuilderTestCase
  # One value per reserved key, so a leak shows up as an attribute in the markup.
  RESERVED_VALUES = {
    label: "Leaked label", help: "Leaked help", control_class: "leaked-control",
    control_data: { leaked: "control" }, addon_class: "leaked-addon",
    field_class: "leaked-field", field_data: { leaked: "field" },
    pattern_type: :number_with_commas, symbol: "@", char_counter: { max: 10 },
    auto_grow: true, select_class: "leaked-select", choose_file_text: "Leaked choose",
    non_selected_text: "Leaked empty", file_class: "leaked-file", icon: "star",
    subtract_data: { leaked: "subtract" }, add_data: { leaked: "add" },
    button_class: "leaked-button", clear: true, manual: true, period: "day",
    mode: "range", alt_input: true, alt_input_class: "leaked-alt", alt_format: "d/m/Y",
    allow_input: true, disable_weekends: true, disabled_dates: [], min_date: "2026-01-01",
    max_date: "2026-12-31", seconds: true, time_24hr: true, default_date: "2026-01-01",
    min_time: "08:00", max_time: "18:00"
  }.freeze

  # `attachments` and `wrapper_options` are nested hashes read before render, and
  # `addon_left`/`addon_right` are markup that is deliberately emitted; none of
  # them can be probed as a scalar attribute value.
  UNPROBED_OPTIONS = %i[attachments wrapper_options addon_left addon_right].freeze

  # Every helper that takes an options hash and renders through Rails.
  HELPERS = {
    "text_field" => ->(b, o) { b.text_field(:name, o) },
    "text_field_group" => ->(b, o) { b.text_field_group(:name, o) },
    "email_field" => ->(b, o) { b.email_field(:name, o) },
    "email_field_group" => ->(b, o) { b.email_field_group(:name, o) },
    "number_field" => ->(b, o) { b.number_field(:name, o) },
    "number_field_group" => ->(b, o) { b.number_field_group(:name, o) },
    "password_field" => ->(b, o) { b.password_field(:name, o) },
    "password_field_group" => ->(b, o) { b.password_field_group(:name, o) },
    "url_field" => ->(b, o) { b.url_field(:name, o) },
    "url_field_group" => ->(b, o) { b.url_field_group(:name, o) },
    "month_field" => ->(b, o) { b.month_field(:name, o) },
    "month_field_group" => ->(b, o) { b.month_field_group(:name, o) },
    "text_area" => ->(b, o) { b.text_area(:name, o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:name, o) },
    "file_field" => ->(b, o) { b.file_field(:name, o) },
    "file_field_group" => ->(b, o) { b.file_field_group(:name, o) },
    "date_field" => ->(b, o) { b.date_field(:name, o) },
    "date_field_group" => ->(b, o) { b.date_field_group(:name, o) },
    "datetime_field" => ->(b, o) { b.datetime_field(:name, o) },
    "datetime_field_group" => ->(b, o) { b.datetime_field_group(:name, o) },
    "time_field" => ->(b, o) { b.time_field(:name, o) },
    "time_field_group" => ->(b, o) { b.time_field_group(:name, o) },
    "search_field_group" => ->(b, o) { b.search_field_group(:name, o) },
    "currency_field_group" => ->(b, o) { b.currency_field_group(:name, o) },
    "percentage_field_group" => ->(b, o) { b.percentage_field_group(:name, o) },
    "step_number_field" => ->(b, o) { b.step_number_field(:name, o) },
    "step_number_field_group" => ->(b, o) { b.step_number_field_group(:name, o) },
    "range_field" => ->(b, o) { b.range_field(:name, o) },
    "range_field_group" => ->(b, o) { b.range_field_group(:name, o) },
    "boolean_field" => ->(b, o) { b.boolean_field(:name, o) },
    "boolean_field_group" => ->(b, o) { b.boolean_field_group(:name, o) },
    "switch_field" => ->(b, o) { b.switch_field(:name, o) },
    "switch_field_group" => ->(b, o) { b.switch_field_group(:name, o) },
    "select_field" => ->(b, o) { b.select_field(:name, [], {}, o) },
    "select_group" => ->(b, o) { b.select_group(:name, [], {}, o) },
    "slim_select_field" => ->(b, o) { b.slim_select_field(:name, [], {}, o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:name, [], {}, o) },
    "time_zone_select" => ->(b, o) { b.time_zone_select(:name, nil, {}, o) },
    "radio_field" => ->(b, o) { b.radio_field(:name, [ %w[One 1] ], {}, o) },
    "radio_field_group" => ->(b, o) { b.radio_field_group(:name, [ %w[One 1] ], {}, o) },
    "rich_text_area" => ->(b, o) { b.rich_text_area(:name, o) },
    "coordinates_polygon_field" => ->(b, o) { b.coordinates_polygon_field(:name, o) },
    "recurrent_event_rule_field" => ->(b, o) { b.recurrent_event_rule_field(:name, o) },
    "time_period_field" => ->(b, o) { b.time_period_field(:name, [ %w[Today today] ], **o) },
    "submit" => ->(b, o) { b.submit("Save", o) },
    "submit_actions" => ->(b, o) { b.submit_actions("Save", o) }
  }.freeze

  def test_reserved_options_list_covers_every_probed_key
    unprobed = Bali::FormBuilder::HtmlUtils::RESERVED_OPTIONS -
               RESERVED_VALUES.keys - UNPROBED_OPTIONS

    assert_empty unprobed,
                 "Reserved options with no probe value, so nothing proves they stop leaking: " \
                 "#{unprobed.inspect}. Add them to RESERVED_VALUES."
  end

  def test_no_reserved_option_reaches_the_dom_as_an_attribute
    leaks = HELPERS.filter_map do |name, render|
      found = attribute_names(render.call(builder, RESERVED_VALUES.dup)) & reserved_attributes
      "#{name}: #{found.sort.inspect}" if found.any?
    end

    assert_empty leaks, "Bali options rendered as HTML attributes:\n#{leaks.join("\n")}"
  end

  def test_no_helper_mutates_the_options_hash_it_is_given
    mutated = HELPERS.filter_map do |name, render|
      options = RESERVED_VALUES.merge(class: "custom", data: { existing: "value" })
      before = Marshal.load(Marshal.dump(options))
      render.call(builder, options)
      "#{name}: #{diff(before, options)}" if options != before
    end

    assert_empty mutated, "Helpers that changed the caller's options hash:\n#{mutated.join("\n")}"
  end

  def test_no_helper_raises_on_a_frozen_options_hash
    failures = HELPERS.filter_map do |name, render|
      render.call(builder, RESERVED_VALUES.merge(class: "custom").freeze)
      nil
    rescue FrozenError => e
      "#{name}: #{e.message}"
    end

    assert_empty failures, "Helpers that mutated a frozen options hash:\n#{failures.join("\n")}"
  end

  # The reported symptom: one hash reused across two fields accumulated the first
  # field's classes into the second.
  def test_reusing_one_options_hash_across_two_fields_does_not_accumulate_classes
    options = { class: "custom-class" }

    first = builder.text_field(:name, options)
    second = builder.text_field(:name, options)

    assert_equal "input input-bordered w-full custom-class", input_class(first)
    assert_equal input_class(first), input_class(second)
  end

  def test_errors_still_render_when_the_options_hash_is_frozen
    resource.errors.add(:name, "is invalid")

    html = builder.text_field(:name, { help: "Ignored while erroring" }.freeze)

    assert_html html, "input.input-error"
    assert_html html, "p.text-error", text: "Name is invalid"
  end

  private

  # ActionText's `rich_text_area` reaches for `main_app`, so this sweep needs a
  # view context with the dummy app's routes rather than a bare one.
  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end

  def reserved_attributes
    Bali::FormBuilder::HtmlUtils::RESERVED_OPTIONS.flat_map do |key|
      [ key.to_s, key.to_s.tr("_", "-") ]
    end
  end

  def attribute_names(html)
    Nokogiri::HTML5.fragment(html.to_s).css("*").flat_map { |node| node.attributes.keys }.uniq
  end

  def input_class(html)
    Nokogiri::HTML5.fragment(html.to_s).at_css("input")["class"]
  end

  def diff(before, after)
    (before.keys | after.keys).filter_map do |key|
      "#{key}: #{before[key].inspect} -> #{after[key].inspect}" if before[key] != after[key]
    end.join(", ")
  end
end
