# frozen_string_literal: true

RRule::Rule.class_eval do
  def humanize(locale = I18n.locale)
    return '' if (humanizer = humanizers[locale.to_sym]).blank?

    humanizer.new(self, options).to_s
  end

  private

  def humanizers
    { es: Rrule::SpanishHumanizer, en: Rrule::EnglishHumanizer }
  end
end
