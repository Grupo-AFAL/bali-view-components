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

  # `delimited: true` is no longer the default, so the cases about the live
  # formatter have to ask for it. See `numeric_options` for why it was reversed.
  DELIMITED = { delimited: true }.freeze

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
    offenders = sweep(**DELIMITED) do |html|
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
      english = render.call(builder, DELIMITED.dup).to_s
      spanish = I18n.with_locale(:es) { render.call(builder, DELIMITED.dup).to_s }

      next "#{name}: English delimiter is not a comma" unless value_in(english, "delimiter") == ","
      next "#{name}: English separator is not a dot" unless value_in(english, "separator") == "."
      next "#{name}: Spanish delimiter is not a dot" unless value_in(spanish, "delimiter") == "."
      next "#{name}: Spanish separator is not a comma" unless value_in(spanish, "separator") == ","

      nil
    end

    assert_empty wrong, "Separators that do not follow the locale:\n#{wrong.join("\n")}"
  end

  # The reversal itself: an amount is not grouped unless the call site says so.
  # It reads like a free upgrade and it is not — the delimiter changes what the
  # field submits, and a grouped amount needs the model concern to survive the
  # trip.
  def test_no_family_groups_unless_the_call_site_asks
    mounted = sweep do |html|
      "number-format is mounted without delimited:" if html.include?("number-format")
    end

    assert_empty mounted, "Fields grouping by default:\n#{mounted.join("\n")}"
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
      render.call(builder, { data: data, **DELIMITED })

      "#{name}: caller's data became #{data.inspect}" unless data == { testid: "budget" }
    end

    assert_empty leaked, "Mutated caller hashes:\n#{leaked.join("\n")}"
  end

  def test_a_caller_supplied_controller_survives_alongside_the_formatter
    dropped = sweep(data: { controller: "autosave" }, **DELIMITED) do |html|
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
      sweep(**DELIMITED) do |html|
        delimiter = value_in(html, "delimiter")

        "delimiter arrived as #{delimiter.inspect}" unless delimiter == " "
      end
    end

    assert_empty lost, "Delimiters lost on the way to the DOM:\n#{lost.join("\n")}"
  end

  # The initial value is grouped by the server, not by the controller. `1.500` is
  # a machine number in English and a delimited fifteen hundred in Spanish, so
  # deciding in the browser meant guessing, and each guess corrupted the case it
  # got wrong.
  def test_a_stored_amount_arrives_already_grouped
    resource.budget = 1_500_200.75

    ungrouped = sweep(**DELIMITED) do |html|
      "value=#{value_attribute(html).inspect}" unless value_attribute(html) == "1,500,200.75"
    end

    assert_empty ungrouped, "Amounts not grouped by the server:\n#{ungrouped.join("\n")}"
  end

  def test_a_stored_amount_is_grouped_in_the_locale_of_the_request
    resource.budget = 1_500_200.75

    wrong = I18n.with_locale(:es) do
      sweep(**DELIMITED) do |html|
        "value=#{value_attribute(html).inspect}" unless value_attribute(html) == "1.500.200,75"
      end
    end

    assert_empty wrong, "Amounts grouped in the wrong locale:\n#{wrong.join("\n")}"
  end

  # The case that made the type the test rather than the shape: after a failed
  # validation `text_field` renders `_before_type_cast`, which is whatever the
  # typist submitted. Grouping that would delete the characters that made it
  # invalid — and reading the CAST value instead would show `1`, the corruption
  # itself.
  def test_what_the_typist_submitted_comes_back_untouched
    resource.budget = "1.234.5abc"

    mangled = sweep(**DELIMITED) do |html|
      "value=#{value_attribute(html).inspect}" unless value_attribute(html) == "1.234.5abc"
    end

    assert_empty mangled, "Rejected input rewritten on re-render:\n#{mangled.join("\n")}"
  end

  def test_a_caller_supplied_value_still_wins
    resource.budget = 1_500_200.75

    overridden = sweep(value: "nada que agrupar", **DELIMITED) do |html|
      "value=#{value_attribute(html).inspect}" unless value_attribute(html) == "nada que agrupar"
    end

    assert_empty overridden, "Callers overridden by the server grouping:\n#{overridden.join("\n")}"
  end

  def test_an_empty_field_gets_no_value_attribute
    leaked = sweep(**DELIMITED) do |html|
      "value=#{value_attribute(html).inspect}" unless value_attribute(html).nil?
    end

    assert_empty leaked, "Empty fields carrying a value:\n#{leaked.join("\n")}"
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

  def value_attribute(html)
    html.to_s[/\svalue="([^"]*)"/, 1]
  end

  def value_in(html, name)
    html.to_s[/data-number-format-#{name}-value="([^"]*)"/, 1]
  end
  # Swaps the two number formats and puts back exactly what was there, using only
  # public API. `store_translations` deep-merges, so the siblings under `number.`
  # — `number.currency`, `number.percentage` — are left alone both ways.
  #
  # The first version put `I18n.backend.reload!` in the `ensure`, which discards
  # the WHOLE backend and not just what it added: every translation any other test
  # or the suite setup had stored programmatically rather than through
  # `load_path` disappeared from that point on, for order-dependent failures
  # nobody would trace back to here. A locale of its own is the other obvious fix
  # and `enforce_available_locales` rejects it.
  def with_number_format(delimiter:, separator:)
    previous = {
      delimiter: I18n.t("number.format.delimiter", locale: :en, default: ","),
      separator: I18n.t("number.format.separator", locale: :en, default: ".")
    }

    store_number_format(delimiter, separator)
    yield
  ensure
    store_number_format(previous[:delimiter], previous[:separator])
  end

  def store_number_format(delimiter, separator)
    I18n.backend.store_translations(
      :en, number: { format: { delimiter: delimiter, separator: separator } }
    )
  end
end
