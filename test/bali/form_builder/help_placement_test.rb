# frozen_string_literal: true

require "test_helper"

# `help:` has to mean the same thing in every field type.
#
# It did not. The families that take a *second* positional hash each decided on
# their own which of the two `field_helper` would see, and the three select
# families chose the last one — so `help:` written next to `label:`, where the
# caller naturally writes it and where every single-hash helper reads it,
# reached the wrapper and never reached the paragraph. It vanished with no
# error, no warning and no failing test: the field rendered, just without its
# hint.
#
# The sweep is the point. Sampling one helper is exactly how this survived: the
# nine single-hash families rendered `help:` correctly the whole time.
class BaliFormBuilderHelpPlacementTest < FormBuilderTestCase
  HELP = "The hint the caller asked for"

  # `nil` where a helper takes a collection or priority-zones argument.
  GROUPS = {
    "text_field_group" => ->(b, o) { b.text_field_group(:name, o) },
    "email_field_group" => ->(b, o) { b.email_field_group(:name, o) },
    "number_field_group" => ->(b, o) { b.number_field_group(:name, o) },
    "password_field_group" => ->(b, o) { b.password_field_group(:name, o) },
    "url_field_group" => ->(b, o) { b.url_field_group(:name, o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:name, o) },
    "file_field_group" => ->(b, o) { b.file_field_group(:name, o) },
    "date_field_group" => ->(b, o) { b.date_field_group(:name, o) },
    "datetime_field_group" => ->(b, o) { b.datetime_field_group(:name, o) },
    "time_field_group" => ->(b, o) { b.time_field_group(:name, o) },
    "month_field_group" => ->(b, o) { b.month_field_group(:name, o) },
    "currency_field_group" => ->(b, o) { b.currency_field_group(:name, o) },
    "percentage_field_group" => ->(b, o) { b.percentage_field_group(:name, o) },
    "step_number_field_group" => ->(b, o) { b.step_number_field_group(:name, o) },
    "boolean_field_group" => ->(b, o) { b.boolean_field_group(:name, o) },
    "switch_field_group" => ->(b, o) { b.switch_field_group(:name, o) },
    # The three that dropped it, and the reason this test exists.
    "select_group" => ->(b, o) { b.select_group(:name, [ %w[A a] ], o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:name, [ %w[A a] ], o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, nil, o) }
  }.freeze

  GROUPS.each do |name, render|
    test "#{name} renders help: written next to label:" do
      html = render.call(builder, { label: "Caption", help: HELP }).to_s

      assert_includes html, HELP,
                      "#{name} swallowed `help:` from the primary options hash"
    end
  end

  # The other half of the contract: a helper with two hashes must not care which
  # one the caller reached for. Only the families that take a second positional
  # hash can express this.
  TWO_HASH_GROUPS = {
    "select_group" => ->(b, o) { b.select_group(:name, [ %w[A a] ], {}, o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:name, [ %w[A a] ], {}, o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, nil, {}, o) }
  }.freeze

  TWO_HASH_GROUPS.each do |name, render|
    test "#{name} also renders help: from the second hash" do
      html = render.call(builder, { help: HELP }).to_s

      assert_includes html, HELP, "#{name} swallowed `help:` from the html_options hash"
    end
  end

  test "the primary hash wins when both carry the same key" do
    html = builder.select_group(:name, [ %w[A a] ], { help: "primary" }, { help: "secondary" }).to_s

    assert_includes html, "primary"
    assert_not_includes html, "secondary"
  end

  # Rendering the hint is only half of it. `aria_attributes` decides whether to
  # emit `aria-describedby` by looking for `help:`, so a helper that renders the
  # paragraph from one hash and builds its aria pair from the other produces a
  # description that exists on screen and not in the accessibility tree — which
  # is worse than no hint at all, because nothing looks wrong.
  TWO_HASH_GROUPS.each_key do |name|
    test "#{name} points aria-describedby at the help it rendered" do
      html = GROUPS.fetch(name).call(builder, { label: "Caption", help: HELP }).to_s

      described_by = html[/aria-describedby="([^"]*)"/, 1]
      paragraph_id = html[/<p[^>]*id="([^"]*help[^"]*)"/, 1]

      assert_not_nil paragraph_id, "#{name} did not render the help paragraph"
      assert_not_nil described_by, "#{name} rendered help but emitted no aria-describedby"
      assert_includes described_by.split, paragraph_id,
                      "#{name}: aria-describedby does not reference the help it rendered"
    end
  end
end
