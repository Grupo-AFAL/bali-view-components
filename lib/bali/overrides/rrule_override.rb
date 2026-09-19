# frozen_string_literal: true

# `humanize` on the host's own RRule::Rule objects, in Spanish or English.
#
# rrule is NOT a dependency of bali_view_components, and this guard is the whole
# reason it does not have to be. The file is `load`ed on every `to_prepare`
# (see lib/bali/engine.rb), so an unguarded `RRule::Rule.class_eval` is a
# NameError during boot — in applications that may never render a recurrence
# rule. Same posture as `rqrcode` in Bali::QrCode::Component: an optional
# library fails where it is used, not where it is absent.
#
# There is nothing to fail at either, which is what makes rrule different from
# rqrcode and cheaper to leave out: Bali never constructs an RRule::Rule. The
# Ruby half of Bali::RecurrentEventRuleForm only moves RRULE strings around, and
# the JS half talks to the npm `rrule` package. This patch decorates objects the
# HOST made, so a host holding one necessarily has the gem — and a host with no
# gem has no object to miss the method on.
#
# `require` rather than `defined?` alone: a Gemfile entry carrying
# `require: false` would otherwise silently lose `humanize`.
begin
  require "rrule"
rescue LoadError
  # No rrule in this bundle. Nothing to patch, and nothing broken.
end

if defined?(RRule::Rule)
  RRule::Rule.class_eval do
    silence_warnings do
      def humanize(locale = I18n.locale)
        return "" if (humanizer = humanizers[locale.to_sym]).blank?

        humanizer.new(self, options).to_s
      end
    end

    private

    def humanizers
      { es: Rrule::SpanishHumanizer, en: Rrule::EnglishHumanizer }
    end
  end
end
