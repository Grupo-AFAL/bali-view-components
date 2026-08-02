# frozen_string_literal: true

require "test_helper"

# `error_and_help` is the builder's single renderer for what it has to say about
# a field. Sweeping every family that renders messages — not sampling one — is
# the point: before this there were four parallel implementations, and each one
# drifted on its own (the checkbox and toggle families never rendered help at
# all, and a textarea with a counter rendered neither help nor error).
class BaliFormBuilderErrorAndHelpTest < FormBuilderTestCase
  HELP = "Some guidance"

  # Every family that renders its own messages, with `help:` in the argument
  # position that family reads it from.
  FAMILIES = {
    "text_field" => ->(b, h) { b.text_field(:name, help: h) },
    "text_group" => ->(b, h) { b.text_group(:name, help: h) },
    "text_field with addons" => ->(b, h) { b.text_field(:name, help: h, addon_left: "$") },
    "text_area" => ->(b, h) { b.text_area(:synopsis, help: h) },
    "text_area with counter" => ->(b, h) { b.text_area(:synopsis, help: h, char_counter: true) },
    "email_field" => ->(b, h) { b.email_field(:name, help: h) },
    "url_field" => ->(b, h) { b.url_field(:name, help: h) },
    "number_field" => ->(b, h) { b.number_field(:budget, help: h) },
    "password_field" => ->(b, h) { b.password_field(:name, help: h) },
    "search_field_group" => ->(b, h) { b.search_field_group(:name, help: h) },
    "file_field" => ->(b, h) { b.file_field(:name, help: h) },
    "select_field" => ->(b, h) { b.select_field(:status, [], help: h) },
    "slim_select_field" => ->(b, h) { b.slim_select_field(:status, [], help: h) },
    "time_zone_select" => ->(b, h) { b.time_zone_select(:name, nil, {}, help: h) },
    "radio_field" => ->(b, h) { b.radio_field(:status, [ %w[One 1] ], help: h) },
    "boolean_field" => ->(b, h) { b.boolean_field(:indie, help: h) },
    "switch_field" => ->(b, h) { b.switch_field(:indie, help: h) },
    "range_field" => ->(b, h) { b.range_field(:rating, help: h) }
  }.freeze

  # The defect this issue is named after: an error used to replace the help text,
  # so the user lost the instruction at the one moment it mattered.
  def test_every_family_renders_help_and_error_together
    failures = FAMILIES.filter_map do |name, render|
      html = render_with_error(render)
      messages = [
        ("no error" unless Capybara.string(html).has_css?("p.text-error")),
        ("no help" unless Capybara.string(html).has_css?("p.fieldset-label", text: HELP))
      ].compact

      "#{name}: #{messages.join(', ')}" if messages.any?
    end

    assert_empty failures, "Helpers that dropped a message:\n#{failures.join("\n")}"
  end

  # A single implementation means a single element, in a single place. Two error
  # paragraphs would mean a family kept its own alongside the shared one.
  def test_every_family_renders_exactly_one_error_and_one_help_paragraph
    failures = FAMILIES.filter_map do |name, render|
      node = Capybara.string(render_with_error(render))
      errors = node.all("p.fieldset-label.text-error", visible: :all).size
      helps = node.all("p.fieldset-label:not(.text-error)", visible: :all).size

      "#{name}: #{errors} error(s), #{helps} help(s)" unless errors == 1 && helps == 1
    end

    assert_empty failures, "Helpers that duplicated a message:\n#{failures.join("\n")}"
  end

  # The ids #674 needs for `aria-describedby`. Wiring them onto the control is
  # that issue's job; emitting them is this one's.
  def test_every_family_gives_its_messages_the_shared_ids
    failures = FAMILIES.filter_map do |name, render|
      node = Capybara.string(render_with_error(render))
      missing = [
        ("error id" unless node.has_css?("p.text-error##{error_id(name)}")),
        ("help id" unless node.has_css?("p.fieldset-label##{help_id(name)}"))
      ].compact

      "#{name}: missing #{missing.join(', ')}" if missing.any?
    end

    assert_empty failures, "Helpers whose messages had no id:\n#{failures.join("\n")}"
  end

  def test_message_ids_follow_the_control_id_rails_derives
    assert_equal "movie_name_error", builder.error_message_id(:name)
    assert_equal "movie_name_help", builder.help_message_id(:name)
  end

  def test_no_message_renders_when_the_field_has_neither_help_nor_error
    html = builder.text_field(:name)

    refute_html html, "p.fieldset-label"
    refute_html html, "p.text-error"
  end

  def test_the_error_comes_before_the_help
    resource.errors.add(:name, "is invalid")

    paragraphs = Capybara.string(builder.text_field(:name, help: HELP)).all("p").map(&:text)

    assert_equal [ "Name is invalid", HELP ], paragraphs
  end

  # Errors are joined into one paragraph, so the id stays unique on the page.
  def test_several_errors_on_one_field_share_a_single_paragraph
    resource.errors.add(:name, "is invalid")
    resource.errors.add(:name, "is too short")

    html = builder.text_field(:name)

    assert_html html, "p#movie_name_error", count: 1
    assert_html html, "p#movie_name_error", text: "Name is invalid, Name is too short"
  end

  private

  # Every family points at whichever attribute it can render, so the error has to
  # be added to that same attribute.
  ERRORED_ATTRIBUTE = {
    "text_area" => :synopsis, "text_area with counter" => :synopsis,
    "number_field" => :budget, "select_field" => :status,
    "slim_select_field" => :status, "radio_field" => :status,
    "boolean_field" => :indie, "switch_field" => :indie, "range_field" => :rating
  }.freeze

  def attribute_for(name)
    ERRORED_ATTRIBUTE.fetch(name, :name)
  end

  def error_id(name) = "movie_#{attribute_for(name)}_error"
  def help_id(name) = "movie_#{attribute_for(name)}_help"

  def render_with_error(render)
    record = Movie.new
    Movie.attribute_names.each { |attribute| record.errors.add(attribute, "is invalid") }

    render.call(movie_form_builder(record), HELP)
  end
end
