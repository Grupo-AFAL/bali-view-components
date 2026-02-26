# frozen_string_literal: true

require "test_helper"

class Bali_FormBuilder_TimeZoneSelectFieldsTest < FormBuilderTestCase
  # #time_zone_select_group

  def test_time_zone_select_group_renders_a_label
    result = builder.time_zone_select_group(:release_date)
    assert_html(result, "legend.fieldset-legend", text: "Release date")
  end

  def test_time_zone_select_group_renders_a_select_tag
    result = builder.time_zone_select_group(:release_date)
    assert_html(result, 'select[name="movie[release_date]"]')
  end

  def test_time_zone_select_group_renders_daisyui_select_classes
    result = builder.time_zone_select_group(:release_date)
    assert_html(result, "select.select.select-bordered.w-full")
  end

  # #time_zone_select

  def test_time_zone_select_renders_a_control_wrapper
    result = builder.time_zone_select(:release_date)
    assert_html(result, "div.control")
  end

  def test_time_zone_select_renders_a_select_tag
    result = builder.time_zone_select(:release_date)
    assert_html(result, 'select[name="movie[release_date]"]')
  end

  def test_time_zone_select_renders_daisyui_base_classes
    result = builder.time_zone_select(:release_date)
    assert_html(result, "select.select.select-bordered.w-full")
  end

  def test_time_zone_select_with_priority_zones_renders_with_priority_zones_at_the_top
    result = builder.time_zone_select(:release_date, ActiveSupport::TimeZone.us_zones)
    assert_html(result, "select option")
  end

  def test_time_zone_select_with_custom_class_appends_custom_class_to_base_classes
    result = builder.time_zone_select(:release_date, nil, {}, { class: "custom" })
    assert_html(result, "select.select.select-bordered.w-full.custom")
  end

  def test_time_zone_select_with_help_text_renders_help_text
    result = builder.time_zone_select(:release_date, nil, {}, { help: "Select your time zone" })
    assert_html(result, "p.label-text-alt", text: "Select your time zone")
  end

  def test_time_zone_select_with_errors_renders_input_error_class
    resource.errors.add(:release_date, "is invalid")
    result = builder.time_zone_select(:release_date)
    assert_html(result, "select.input-error")
  end

  def test_time_zone_select_with_errors_renders_error_message
    resource.errors.add(:release_date, "is invalid")
    result = builder.time_zone_select(:release_date)
    assert_html(result, "p.text-error", text: "Release date is invalid")
  end

  def test_time_zone_select_does_not_mutate_input_hashes_preserves_the_original_html_options_hash
    html_options = { class: "my-class", help: "Help text" }
    original_keys = html_options.keys.dup
    builder.time_zone_select(:release_date, nil, {}, html_options)
    assert_equal original_keys, html_options.keys
  end
end
