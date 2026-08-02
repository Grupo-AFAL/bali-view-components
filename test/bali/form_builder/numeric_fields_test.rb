# frozen_string_literal: true

require "test_helper"

# What `currency_field_group` and `percentage_field_group` share. Both delegate
# to `numeric_field_group`, so each case is swept over the two rather than
# asserted on one: they used to be independent copies of the same six lines,
# which is how they came to carry the same two bugs.
class BaliFormBuilderNumericFieldsTest < FormBuilderTestCase
  FAMILIES = {
    "currency_field_group" => ->(b, o) { b.currency_field_group(:budget, o) },
    "percentage_field_group" => ->(b, o) { b.percentage_field_group(:budget, o) }
  }.freeze

  # `step` only means anything on a `number`, a `range` or a date input. These
  # are `text` — they have to be, or the thousands delimiter cannot survive
  # being typed — so the attribute was inert and told the reader something
  # false about the field.
  def test_no_family_renders_a_step_on_its_text_input
    offenders = sweep { |html| "still renders step=#{html[/step="([^"]*)"/, 1].inspect}" \
      if html.match?(/step="/) }

    assert_empty offenders, "A step on a text input does nothing:\n#{offenders.join("\n")}"
  end

  # A bare text input opens the alphabetic keyboard on a phone. `decimal` opens
  # the numeric one, with the locale's decimal key on it.
  def test_every_family_asks_for_the_decimal_keyboard
    offenders = sweep do |html|
      "inputmode=#{html[/inputmode="([^"]*)"/, 1].inspect}" unless html.include?('inputmode="decimal"')
    end

    assert_empty offenders, "Fields opening the wrong keyboard:\n#{offenders.join("\n")}"
  end

  # The bug this whole front existed to fix: the pattern was a frozen English
  # literal, so an amount written the correct Spanish way — `1.234,56` — was
  # rejected by the browser before it ever reached the server.
  def test_the_pattern_follows_the_active_locale
    wrong = FAMILIES.filter_map do |name, render|
      english = Regexp.new(pattern_in(render.call(builder, {})))
      spanish = Regexp.new(I18n.with_locale(:es) { pattern_in(render.call(builder, {})) })

      next "#{name}: the English pattern rejects 1,234.56" unless english.match?("1,234.56")
      next "#{name}: the Spanish pattern rejects 1.234,56" unless spanish.match?("1.234,56")
      next "#{name}: the English pattern accepts the Spanish shape" if english.match?("1.234,56")
      next "#{name}: the Spanish pattern accepts the English shape" if spanish.match?("1,234.56")

      nil
    end

    assert_empty wrong, "Patterns that do not follow the locale:\n#{wrong.join("\n")}"
  end

  def test_a_caller_supplied_option_still_wins_over_the_defaults
    overridden = sweep(placeholder: "0.00", inputmode: "numeric") do |html|
      next "placeholder was overridden" unless html.include?('placeholder="0.00"')
      next "inputmode was overridden" unless html.include?('inputmode="numeric"')

      nil
    end

    assert_empty overridden, "Defaults beating the caller:\n#{overridden.join("\n")}"
  end

  private

  def sweep(options = {})
    FAMILIES.filter_map do |name, render|
      complaint = yield(render.call(builder, options).to_s)
      "#{name}: #{complaint}" if complaint
    end
  end

  def pattern_in(html)
    html.to_s[/pattern="([^"]*)"/, 1]
  end
end
