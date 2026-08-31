# frozen_string_literal: true

require "test_helper"

# What `currency_group` and `percentage_group` share. Both delegate
# to `numeric_group`, so each case is swept over the two rather than
# asserted on one: they used to be independent copies of the same six lines,
# which is how they came to carry the same two bugs.
class BaliFormBuilderNumericFieldsTest < FormBuilderTestCase
  FAMILIES = {
    "currency_group" => ->(b, o) { b.currency_group(:budget, **o) },
    "percentage_group" => ->(b, o) { b.percentage_group(:budget, **o) }
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

  # The delimiter used to be something the typist had to enter by hand: the field
  # accepted it and the server parsed it back out, but nobody put it there.
  def test_every_family_mounts_the_live_formatter
    offenders = sweep do |html|
      "no number-format controller" unless html.include?('data-controller="number-format"')
    end

    assert_empty offenders, "Fields with no live grouping:\n#{offenders.join("\n")}"
  end

  # The controller cannot read the separators from the browser: `Intl` would
  # resolve them from the browser's locale, while the value it produces is parsed
  # back with Rails'. An English browser on a Spanish form would have had the two
  # halves disagree on which character is the decimal point.
  def test_the_formatter_is_handed_the_separators_of_the_active_locale
    wrong = FAMILIES.filter_map do |name, render|
      english = render.call(builder, {}).to_s
      spanish = I18n.with_locale(:es) { render.call(builder, {}).to_s }

      next "#{name}: English delimiter is not a comma" unless value_in(english, "delimiter") == ","
      next "#{name}: English separator is not a dot" unless value_in(english, "separator") == "."
      next "#{name}: Spanish delimiter is not a dot" unless value_in(spanish, "delimiter") == "."
      next "#{name}: Spanish separator is not a comma" unless value_in(spanish, "separator") == ","

      nil
    end

    assert_empty wrong, "Separators that do not follow the locale:\n#{wrong.join("\n")}"
  end

  def test_delimited_false_leaves_the_field_unformatted
    still_mounted = sweep(delimited: false) do |html|
      "number-format is still mounted" if html.include?("number-format")
    end

    assert_empty still_mounted, "Fields ignoring delimited: false:\n#{still_mounted.join("\n")}"
  end

  # `prepend_controller` mutates the hash it is given, and `dup` alone leaves the
  # nested `:data` pointing at the caller's object — which is how one field comes
  # to carry the previous field's Stimulus wiring.
  def test_the_caller_keeps_its_own_data_hash
    leaked = FAMILIES.filter_map do |name, render|
      data = { testid: "budget" }
      render.call(builder, { data: data })

      "#{name}: caller's data became #{data.inspect}" unless data == { testid: "budget" }
    end

    assert_empty leaked, "Mutated caller hashes:\n#{leaked.join("\n")}"
  end

  def test_a_caller_supplied_controller_survives_alongside_the_formatter
    dropped = sweep(data: { controller: "autosave" }) do |html|
      controllers = html[/data-controller="([^"]*)"/, 1].to_s.split

      "data-controller=#{controllers.inspect}" unless controllers.sort == %w[autosave number-format]
    end

    assert_empty dropped, "Fields that dropped a caller's controller:\n#{dropped.join("\n")}"
  end

  # A space is the thousands delimiter in `fr`, `pl` and `sv`, and the natural way
  # to hand it to Stimulus — `prepend_values` — space-joins and then strips, so it
  # would have arrived as an empty string and turned the grouping off in exactly
  # the locales whose delimiter is hardest to type by hand.
  def test_a_delimiter_that_is_a_space_reaches_the_browser_intact
    lost = with_number_format(delimiter: " ", separator: ",") do
      sweep do |html|
        delimiter = value_in(html, "delimiter")

        "delimiter arrived as #{delimiter.inspect}" unless delimiter == " "
      end
    end

    assert_empty lost, "Delimiters lost on the way to the DOM:\n#{lost.join("\n")}"
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

  def value_in(html, name)
    html.to_s[/data-number-format-#{name}-value="([^"]*)"/, 1]
  end
  # Rails' own English number formats are what every other case here runs
  # against; this swaps them for one call so a space delimiter can be measured
  # without depending on which locales the host happens to ship.
  def with_number_format(delimiter:, separator:)
    I18n.backend.store_translations(
      :en, number: { format: { delimiter: delimiter, separator: separator } }
    )
    yield
  ensure
    I18n.backend.reload!
  end
end
