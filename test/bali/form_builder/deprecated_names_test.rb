# frozen_string_literal: true

require "test_helper"

# The rest of the suite was migrated to the v3 spellings in the same commit that
# introduced them, so nothing in it calls the compatibility layer — which means
# nothing in it would notice if the layer stopped working, or stopped warning.
# These tests call the v2 names on purpose.
class BaliFormBuilderDeprecatedNamesTest < FormBuilderTestCase
  # Every shipped shim, and the new name each one must reach. Driving the test
  # off the module's own tables is what keeps a name from being added to one and
  # forgotten in the other.
  def test_every_shimmed_option_group_renders_what_the_new_name_renders
    assert_predicate Bali::FormBuilder::DeprecatedNames::RENAMED_OPTION_GROUPS, :any?

    Bali::FormBuilder::DeprecatedNames::RENAMED_OPTION_GROUPS.each do |old_name, new_name|
      old_html = Bali.deprecator.silence { builder.public_send(old_name, :name).to_s }
      new_html = builder.public_send(new_name, :name).to_s

      assert_equal new_html, old_html, "#{old_name} does not render what #{new_name} renders"
    end
  end

  def test_every_shimmed_checked_group_renders_what_the_new_name_renders
    Bali::FormBuilder::DeprecatedNames::RENAMED_CHECKED_GROUPS.each do |old_name, new_name|
      old_html = Bali.deprecator.silence { builder.public_send(old_name, :indie).to_s }
      new_html = builder.public_send(new_name, :indie).to_s

      assert_equal new_html, old_html, "#{old_name} does not render what #{new_name} renders"
    end
  end

  def test_every_shimmed_name_warns_through_bali_deprecator
    names = Bali::FormBuilder::DeprecatedNames::RENAMED_OPTION_GROUPS.keys +
            Bali::FormBuilder::DeprecatedNames::RENAMED_CHECKED_GROUPS.keys

    names.each do |old_name|
      assert_deprecated(/#{old_name} is deprecated/, Bali.deprecator) do
        builder.public_send(old_name, :name)
      end
    end
  end

  def test_a_shim_still_forwards_the_options_hash
    html = Bali.deprecator.silence do
      builder.text_field_group(:name, label: "Caption", help: "Hint").to_s
    end

    assert_html html, "label.fieldset-legend[for=movie_name]", text: "Caption"
    assert_html html, "p.fieldset-label", text: "Hint"
  end

  # The v2 spelling of the one pair that could not be reached without also
  # spelling out the options hash.
  def test_the_checked_value_shim_forwards_both_trailing_positional_values
    html = Bali.deprecator.silence do
      builder.boolean_field_group(:indie, {}, "yes", "no").to_s
    end

    assert_includes html, 'value="yes"'
    assert_includes html, 'value="no"'
  end

  def test_the_radio_shim_moves_its_second_hash_onto_html
    values = [ %w[One 1], %w[Two 2] ]

    old_html = Bali.deprecator.silence do
      builder.radio_field_group(:status, values, { label: "Status" }, { size: :lg }).to_s
    end
    new_html = builder.radio_group(:status, values, label: "Status", html: { size: :lg }).to_s

    assert_equal new_html, old_html
    assert_includes old_html, "radio-lg"
  end

  def test_radio_field_group_warns
    assert_deprecated(/radio_field_group is deprecated/, Bali.deprecator) do
      builder.radio_field_group(:status, [ %w[One 1] ])
    end
  end

  # The renames nobody calls. A `NoMethodError` here is the deliberate outcome,
  # not an oversight: see the comment on DeprecatedNames.
  UNSHIMMED = %i[
    coordinates_polygon_field_group direct_upload_field_group numeric_field_group
    recurrent_event_rule_field_group step_number_field_group time_period_field_group
    datetime_select_group
  ].freeze

  def test_the_renames_with_no_measured_traffic_are_gone_rather_than_shimmed
    UNSHIMMED.each do |name|
      assert_not builder.respond_to?(name), "#{name} should have been removed, not shimmed"
    end
  end

  # The three select families kept their names and changed their call shape.
  # These are the v2 shapes measured in the host applications.
  def test_select_group_accepts_the_v2_positional_pair
    values = [ %w[A a], %w[B b] ]

    old_html = Bali.deprecator.silence do
      builder.select_group(:name, values, { include_blank: "Pick" }, { class: "w-32" }).to_s
    end
    new_html = builder.select_group(
      :name, values, include_blank: "Pick", html: { class: "w-32" }
    ).to_s

    assert_equal new_html, old_html
  end

  def test_select_group_accepts_a_lone_v2_options_hash
    values = [ %w[A a] ]

    old_html = Bali.deprecator.silence do
      builder.select_group(:name, values, { label: "Caption" }).to_s
    end

    assert_equal builder.select_group(:name, values, label: "Caption").to_s, old_html
  end

  # `f.select_group :x, values, {}, select_class: 'foo'` — the shape where the
  # trailing keywords were the html hash, not the options hash. Reading them as
  # options would move `class:` off the element without saying so.
  def test_the_v2_shape_where_trailing_keywords_were_the_html_hash
    values = [ %w[A a] ]

    old_html = Bali.deprecator.silence do
      builder.select_group(:name, values, {}, class: "w-32").to_s
    end

    assert_equal builder.select_group(:name, values, html: { class: "w-32" }).to_s, old_html
    assert_html old_html, "select.w-32"
  end

  def test_the_positional_pair_warns
    assert_deprecated(/no longer takes positional option hashes/, Bali.deprecator) do
      builder.slim_select_group(:name, [ %w[A a] ], { label: "Caption" })
    end
  end

  def test_the_keyword_call_does_not_warn
    assert_not_deprecated(Bali.deprecator) do
      builder.select_group(:name, [ %w[A a] ], label: "Caption", html: { class: "w-32" })
    end
  end

  # The Rails-named overrides are not deprecated: they are how Rails and its
  # ecosystem reach these controls, and they still render Bali's markup.
  def test_the_rails_named_overrides_still_render_bali_markup_without_warning
    assert_not_deprecated(Bali.deprecator) do
      assert_equal builder.text_area_field(:synopsis).to_s, builder.text_area(:synopsis).to_s
      assert_equal builder.time_zone_select_field(:name).to_s,
                   builder.time_zone_select(:name).to_s
    end
  end
end
