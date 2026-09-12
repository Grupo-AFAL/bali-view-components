# frozen_string_literal: true

require "test_helper"

# `error:` is the caller's own message for a field (#723): what rodauth — or any
# validator that is not ActiveModel — produced, on a form that may not have an
# object at all. It joins the model's errors rather than replacing them, the
# caller's message first, and rides the exact plumbing model errors already
# use: the `.text-error` paragraph, the `aria-describedby`/`aria-invalid` pair,
# and the family's `*-error` class on the control.
#
# Not every family has all three to offer, so — like `required_option_test` —
# every group helper has to declare its outcome by name: the full dress, the
# message alone, or nothing at all (the families that never rendered field
# messages, model errors included). Anything undeclared is the drift this test
# exists for.
class BaliFormBuilderExternalErrorOptionTest < FormBuilderTestCase
  MESSAGE = "External message"

  # Message paragraph + aria pair + the family's error class on the control.
  MARKS_CONTROL = {
    "text_group" => [ ->(b, o) { b.text_group(:name, **o) }, "input-error" ],
    "email_group" => [ ->(b, o) { b.email_group(:name, **o) }, "input-error" ],
    "url_group" => [ ->(b, o) { b.url_group(:name, **o) }, "input-error" ],
    "password_group" => [ ->(b, o) { b.password_group(:name, **o) }, "input-error" ],
    "number_group" => [ ->(b, o) { b.number_group(:budget, **o) }, "input-error" ],
    "month_group" => [ ->(b, o) { b.month_group(:release_date, **o) }, "input-error" ],
    "date_group" => [ ->(b, o) { b.date_group(:release_date, **o) }, "input-error" ],
    "datetime_group" => [ ->(b, o) { b.datetime_group(:release_date, **o) }, "input-error" ],
    "time_group" => [ ->(b, o) { b.time_group(:duration, **o) }, "input-error" ],
    "search_group" => [ ->(b, o) { b.search_group(:name, **o) }, "input-error" ],
    "currency_group" => [ ->(b, o) { b.currency_group(:budget, **o) }, "input-error" ],
    "percentage_group" => [ ->(b, o) { b.percentage_group(:budget, **o) }, "input-error" ],
    "numeric_group" => [ ->(b, o) { b.numeric_group(:budget, **o) }, "input-error" ],
    "step_number_group" => [ ->(b, o) { b.step_number_group(:duration, **o) }, "input-error" ],
    "text_area_group" => [ ->(b, o) { b.text_area_group(:synopsis, **o) }, "textarea-error" ],
    "range_group" => [ ->(b, o) { b.range_group(:rating, **o) }, "range-error" ],
    "boolean_group" => [ ->(b, o) { b.boolean_group(:indie, **o) }, "checkbox-error" ],
    "switch_group" => [ ->(b, o) { b.switch_group(:indie, **o) }, "toggle-error" ],
    "select_group" => [ ->(b, o) { b.select_group(:status, [], **o) }, "select-error" ],
    "slim_select_group" => [ ->(b, o) { b.slim_select_group(:status, [], **o) }, "select-error" ],
    "time_zone_select_group" => [ ->(b, o) { b.time_zone_select_group(:name, **o) },
                                  "select-error" ],
    "radio_group" => [ ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) }, "radio-error" ],
    # The error class lands on the `<trix-editor>`: the widget goes through
    # `field_options` like a text input, so it dresses like one.
    "rich_text_area_group" => [ ->(b, o) { b.rich_text_area_group(:synopsis, **o) },
                                "input-error" ]
  }.freeze

  # Message paragraph only. `file_group`'s native input is hidden behind the
  # browse button, so its class would color nothing (the aria pair still lands
  # on it). The two editors and the toggler composite render widgets that carry
  # no error dress today — model errors get exactly the same treatment.
  MESSAGE_ONLY = {
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "rich_text_group" => ->(b, o) { b.rich_text_group(:synopsis, **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "radio_buttons_group" => ->(b, o) { b.radio_buttons_group(:status, { a: [ %w[One 1] ] }, **o) }
  }.freeze

  # Families that render no field messages at all — for model errors too, and
  # since before this option existed. Named so the silence stays a decision:
  # moving one out of here means giving it the message paragraph, not deleting
  # the line.
  NO_MESSAGE = {
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "recurrent_event_rule_group" => ->(b, o) { b.recurrent_event_rule_group(:rule, **o) },
    "direct_upload_group" => ->(b, o) { b.direct_upload_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) }
  }.freeze

  # Renders a button and a container for nested records, never a control of its
  # own, and needs a real association to render at all.
  UNSWEPT_GROUPS = %w[dynamic_fields_group].freeze

  def test_every_group_helper_is_covered_by_this_sweep
    swept = MARKS_CONTROL.keys + MESSAGE_ONLY.keys + NO_MESSAGE.keys + UNSWEPT_GROUPS
    uncovered = live_group_helpers - swept

    assert_empty uncovered,
                 "Group helpers with no `error:` expectation, so nothing says what the " \
                 "explicit error does there: #{uncovered.sort.inspect}. Add each to " \
                 "MARKS_CONTROL, MESSAGE_ONLY or NO_MESSAGE."
  end

  def test_explicit_error_reaches_message_aria_and_control_class
    failures = MARKS_CONTROL.filter_map do |name, (render, error_class)|
      html = render.call(builder, { error: MESSAGE })
      problems = [
        (:message unless error_paragraphs(html) == [ MESSAGE ]),
        (:aria_invalid if invalid_elements(html).empty?),
        (:aria_describedby unless described_by_error?(html)),
        ("class #{error_class}" unless class_on_some_element?(html, error_class))
      ].compact
      "#{name}: missing #{problems.inspect}" if problems.any?
    end

    assert_empty failures, "`error:` did not fully dress the control:\n#{failures.join("\n")}"
  end

  def test_explicit_error_renders_the_message_where_only_the_message_fits
    failures = MESSAGE_ONLY.filter_map do |name, render|
      html = render.call(builder, { error: MESSAGE })
      "#{name}: #{error_paragraphs(html).inspect}" unless error_paragraphs(html) == [ MESSAGE ]
    end

    assert_empty failures, "`error:` message paragraph missing:\n#{failures.join("\n")}"
  end

  def test_explicit_error_stays_silent_where_no_messages_render
    failures = NO_MESSAGE.filter_map do |name, render|
      html = render.call(builder, { error: MESSAGE })
      "#{name}" if error_paragraphs(html).any?
    end

    assert_empty failures,
                 "Families declared message-less rendered one — move them out of " \
                 "NO_MESSAGE:\n#{failures.join("\n")}"
  end

  # D723-2: union, explicit first — the mirror of the error+help decision.
  def test_explicit_error_joins_the_models_errors_explicit_first
    resource.errors.add(:name, "is invalid")

    html = builder.text_group(:name, error: MESSAGE)

    assert_equal [ "#{MESSAGE}, Name is invalid" ], error_paragraphs(html)
  end

  def test_an_array_of_errors_renders_joined_in_order
    html = builder.text_group(:name, error: [ "Too short", "Too plain" ])

    assert_equal [ "Too short, Too plain" ], error_paragraphs(html)
  end

  # nil, false and "" all mean "nothing to add", so a call site can pass the
  # raw return of `rodauth.field_error(param)` without guarding it first.
  def test_blank_errors_render_nothing
    [ nil, false, "" ].each do |blank|
      html = builder.text_group(:name, error: blank)

      assert_empty error_paragraphs(html), "error: #{blank.inspect} rendered a paragraph"
      assert_empty invalid_elements(html), "error: #{blank.inspect} marked the control invalid"
    end
  end

  # The consumer the option exists for: `form_with url:` and no object. The
  # ids come out bare (`login_error`), and the whole dress still applies.
  def test_a_builder_without_an_object_carries_the_explicit_error
    html = objectless_builder.text_group(:login, error: "Bad login")

    assert_equal [ "Bad login" ], error_paragraphs(html)
    assert_html html, "input.input-error[aria-invalid='true'][aria-describedby='login_error']"
    assert_html html, "p.text-error#login_error"
  end

  def test_a_builder_without_an_object_and_without_an_error_stays_clean
    html = objectless_builder.text_group(:login, error: nil)

    assert_empty error_paragraphs(html)
    assert_empty invalid_elements(html)
  end

  # The two-hash families accept the option on either side: `group_options`
  # reads the wrapper keys out of both, primary hash first.
  def test_select_families_accept_error_inside_html_too
    html = builder.select_group(:status, [], html: { error: MESSAGE })

    assert_equal [ MESSAGE ], error_paragraphs(html)
    assert_html html, "select.select-error[aria-invalid='true']"
  end

  private

  def error_paragraphs(html)
    Nokogiri::HTML5.fragment(html.to_s).css("p.text-error").map(&:text)
  end

  def invalid_elements(html)
    Nokogiri::HTML5.fragment(html.to_s).css("[aria-invalid='true']").map(&:name)
  end

  def described_by_error?(html)
    Nokogiri::HTML5.fragment(html.to_s).css("[aria-describedby]").any? do |node|
      node["aria-describedby"].split.any? { |id| id.end_with?("_error") }
    end
  end

  def class_on_some_element?(html, error_class)
    Nokogiri::HTML5.fragment(html.to_s).css("[class~='#{error_class}']").any?
  end

  def live_group_helpers
    deprecated = Bali::FormBuilder::DeprecatedNames.instance_methods.map(&:to_s)

    Bali::FormBuilder.instance_methods.map(&:to_s).grep(/_group\z/) - deprecated
  end

  def objectless_builder
    @objectless_builder ||= Bali::FormBuilder.new(nil, nil, vc_test_controller.view_context, {})
  end

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
