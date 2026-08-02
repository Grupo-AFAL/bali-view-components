# frozen_string_literal: true

require "test_helper"

# `required:` is a plain HTML attribute: the builder does not read it, Rails
# forwards it, and it lands on whatever element the family renders. That is fine
# for the twenty families whose control is a native input, and it was a lie for
# the rest — `<div required>`, `<trix-editor required>` and `<button required>`
# are not valid, do nothing, and read at the call site as if the browser were
# now enforcing the field.
#
# So the contract has exactly two outcomes, and every helper has to be in one of
# them by name: the attribute reaches a control the browser validates, or it
# reaches nothing at all. Anything in between is the bug this test exists for.
class BaliFormBuilderRequiredOptionTest < FormBuilderTestCase
  # Elements the browser runs constraint validation on. `<button>` is not one of
  # them, and neither is any custom element.
  VALIDATABLE = %w[input select textarea].freeze

  CARRIES = {
    "text_group" => ->(b, o) { b.text_group(:name, **o) },
    "text_field" => ->(b, o) { b.text_field(:name, **o) },
    "email_group" => ->(b, o) { b.email_group(:name, **o) },
    "url_group" => ->(b, o) { b.url_group(:name, **o) },
    "password_group" => ->(b, o) { b.password_group(:name, **o) },
    "number_group" => ->(b, o) { b.number_group(:budget, **o) },
    "month_group" => ->(b, o) { b.month_group(:release_date, **o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:synopsis, **o) },
    "date_group" => ->(b, o) { b.date_group(:release_date, **o) },
    "datetime_group" => ->(b, o) { b.datetime_group(:release_date, **o) },
    "time_group" => ->(b, o) { b.time_group(:duration, **o) },
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "search_group" => ->(b, o) { b.search_group(:name, **o) },
    "currency_group" => ->(b, o) { b.currency_group(:budget, **o) },
    "percentage_group" => ->(b, o) { b.percentage_group(:budget, **o) },
    "numeric_group" => ->(b, o) { b.numeric_group(:budget, **o) },
    "step_number_group" => ->(b, o) { b.step_number_group(:duration, **o) },
    "range_group" => ->(b, o) { b.range_group(:rating, **o) },
    "boolean_group" => ->(b, o) { b.boolean_group(:indie, **o) },
    "switch_group" => ->(b, o) { b.switch_group(:indie, **o) },
    "select_group" => ->(b, o) { b.select_group(:status, [], html: o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [], html: o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, html: o) }
  }.freeze

  # Everything whose "control" is a widget over a hidden field, plus the submit
  # button. A hidden input is barred from constraint validation, so there is no
  # element here that `required` could have been put on and worked.
  #
  # `radio_group` is in this list for a different reason, and it is the one worth
  # remembering: its per-input attributes travel in `html:`, so a top-level
  # `required:` is a group option and never reaches a radio. Passing it in
  # `html:` does reach them — asserted below.
  DROPS = {
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) },
    "radio_buttons_group" => ->(b, o) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "rich_text_area_group" => ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    "submit_field" => ->(b, o) { b.submit_field("Save", **o) },
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) }
  }.freeze

  # `dynamic_fields_group` renders a button and a container for nested records,
  # never a control of its own, and it needs a real association to render at all.
  # Named here rather than left out silently, so the coverage check below stays
  # a check.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  def test_every_group_helper_is_covered_by_this_sweep
    swept = CARRIES.keys + DROPS.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `required:` expectation, so nothing says where the " \
                 "attribute goes: #{uncovered.sort.inspect}. Add each to CARRIES or DROPS."
  end

  def test_required_reaches_a_validatable_control
    missing = CARRIES.filter_map do |name, render|
      elements = required_elements(render.call(builder, { required: true }))
      "#{name}: #{elements.inspect}" unless elements.any? { |tag| VALIDATABLE.include?(tag) }
    end

    assert_empty missing,
                 "`required: true` never reached a control the browser validates:\n" \
                 "#{missing.join("\n")}"
  end

  def test_required_is_dropped_where_no_control_could_carry_it
    emitted = DROPS.filter_map do |name, render|
      elements = required_elements(render.call(builder, { required: true }))
      "#{name}: #{elements.inspect}" if elements.any?
    end

    assert_empty emitted,
                 "`required` emitted on an element that cannot be validated:\n" \
                 "#{emitted.join("\n")}"
  end

  # The other half of `radio_group`'s story: the attribute is not lost, it is in
  # the hash the family reads element attributes from.
  def test_radio_group_puts_required_on_its_inputs_when_it_travels_in_html
    html = builder.radio_group(:status, [ %w[One 1], %w[Two 2] ], html: { required: true })

    assert_equal %w[input input], required_elements(html)
  end

  private

  def live_group_helpers
    deprecated = Bali::FormBuilder::DeprecatedNames.instance_methods.map(&:to_s)

    Bali::FormBuilder.instance_methods.map(&:to_s).grep(/_group\z/) - deprecated
  end

  def required_elements(html)
    Nokogiri::HTML5.fragment(html.to_s).css("[required]").map(&:name)
  end

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
