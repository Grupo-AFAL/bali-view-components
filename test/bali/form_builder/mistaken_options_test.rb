# frozen_string_literal: true

require "test_helper"

# A key the builder does not read is forwarded to Rails, and Rails puts anything
# it does not recognise on the element. That is deliberate — it is how `accept:`,
# `autocomplete:` and every other real attribute reach the input without Bali
# having to list them.
#
# The cost is that a key which only *looks* like a Bali option gets the same
# treatment, and #1111 measured both halves of it: `hint:` painted
# `hint="Formato CSV…"` on the input and rendered no help text anywhere, and
# `input_options: { name: "import[file]" }` left the input named `file`, so the
# POST hit `params.require(:import)` and 400'd behind a Turbo response nobody saw.
#
# Neither key is a valid HTML attribute, so neither can be a call site asking for
# one. They are named, dropped, and said out loud.
class BaliFormBuilderMistakenOptionsTest < FormBuilderTestCase
  # Every family that builds element attributes, so nothing can quietly keep
  # forwarding a mistaken key. The two select families that never leaked it are
  # here too: they dropped it without a trace, which is the same silence.
  HELPERS = {
    "text_group" => ->(b, o) { b.text_group(:name, **o) },
    "file_group" => ->(b, o) { b.file_group(:name, **o) },
    "text_area_group" => ->(b, o) { b.text_area_group(:synopsis, **o) },
    "date_group" => ->(b, o) { b.date_group(:release_date, **o) },
    "select_group" => ->(b, o) { b.select_group(:status, [], **o) },
    "slim_select_group" => ->(b, o) { b.slim_select_group(:status, [], **o) },
    "time_zone_select_group" => ->(b, o) { b.time_zone_select_group(:name, **o) },
    "radio_group" => ->(b, o) { b.radio_group(:status, [ %w[One 1] ], **o) },
    "boolean_group" => ->(b, o) { b.boolean_group(:indie, **o) },
    "switch_group" => ->(b, o) { b.switch_group(:indie, **o) },
    "range_group" => ->(b, o) { b.range_group(:rating, **o) },
    "block_editor_group" => ->(b, o) { b.block_editor_group(:synopsis, **o) },
    "coordinates_polygon_group" => ->(b, o) { b.coordinates_polygon_group(:name, **o) },
    "time_period_group" => ->(b, o) { b.time_period_group(:release_date, [ %w[T t] ], **o) },
    "submit_group" => ->(b, o) { b.submit_group("Save", **o) }
  }.freeze

  def test_every_mistaken_key_has_a_correction_to_offer
    silent = Bali::FormBuilder::HtmlUtils::MISTAKEN_OPTIONS.reject { |_, text| text.present? }

    assert_empty silent,
                 "A mistaken key with no correction says the call site is wrong and not what " \
                 "to write instead: #{silent.keys.inspect}"
  end

  def test_no_mistaken_key_reaches_the_dom_as_an_attribute
    leaks = Bali::FormBuilder::HtmlUtils::MISTAKEN_OPTIONS.each_key.flat_map do |key|
      HELPERS.filter_map do |name, render|
        html = silence_deprecations { render.call(fresh_builder, key => "Formato CSV") }
        "#{name}: #{key}" if attribute_names(html).include?(key.to_s)
      end
    end

    assert_empty leaks, "A mistaken option rendered as an HTML attribute:\n#{leaks.join("\n")}"
  end

  def test_every_family_says_out_loud_that_it_ignored_the_key
    Bali::FormBuilder::HtmlUtils::MISTAKEN_OPTIONS.each_key do |key|
      silent = HELPERS.reject do |_, render|
        capture_deprecation { render.call(fresh_builder, key => "Formato CSV") }
      end

      assert_empty silent.keys,
                   "`#{key}:` was ignored without a word by: #{silent.keys.inspect}"
    end
  end

  def test_the_warning_names_the_option_and_what_to_write_instead
    message = capture_deprecation do
      fresh_builder.file_group(:file, hint: "Formato CSV con columnas…")
    end

    assert_includes message, "`hint:` is not an option"
    assert_includes message, "`help:`"
  end

  def test_input_options_points_at_the_escape_hatch_that_does_exist
    message = capture_deprecation do
      fresh_builder.file_group(:file, input_options: { name: "import[file]" })
    end

    assert_includes message, "`input_options:` is not an option"
    assert_includes message, "`input_name:`"
  end

  # The option the call site meant. Nothing about the fix may cost `help:` its
  # paragraph — that is the text the report was trying to render in the first place.
  def test_help_still_renders_under_a_file_field
    html = builder.file_group(:file, help: "Formato CSV con columnas…")

    assert_html html, "p.fieldset-label", text: "Formato CSV con columnas…"
  end

  # A form repeating one typo across six fields has one thing wrong with it, and
  # six identical lines is how a log gets skimmed.
  def test_one_warning_per_key_per_form
    warnings = []

    with_deprecator_behavior(->(message, *) { warnings << message }) do
      b = fresh_builder
      b.text_group(:name, hint: "one")
      b.text_group(:name, hint: "two")
      b.file_group(:file, hint: "three")
    end

    assert_equal 1, warnings.size, "Expected one warning, got:\n#{warnings.join("\n")}"
  end

  def test_a_second_form_warns_again
    warnings = []

    with_deprecator_behavior(->(message, *) { warnings << message }) do
      fresh_builder.text_group(:name, hint: "one")
      fresh_builder.text_group(:name, hint: "two")
    end

    assert_equal 2, warnings.size
  end

  def test_a_correct_form_says_nothing
    assert_nil capture_deprecation {
      fresh_builder.file_group(:file, help: "Formato CSV", input_name: "import[file]", accept: ".csv")
    }
  end

  private

  def attribute_names(html)
    Nokogiri::HTML5.fragment(html.to_s).css("*").flat_map { |node| node.attributes.keys }.uniq
  end

  # The guard that keeps a form from warning twice lives on the builder, so a test
  # asserting the first warning needs a builder that has not warned yet.
  def fresh_builder
    Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end

  def builder
    @builder ||= fresh_builder
  end
end
