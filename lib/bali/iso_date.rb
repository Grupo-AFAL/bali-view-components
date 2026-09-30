# frozen_string_literal: true

module Bali
  # A YYYY-MM-DD date read from outside — a param, a JSON payload — or nil.
  #
  # `Date.iso8601` on its own is not that. It reads "2026-09" as the 1st, "--09-10" in the
  # current year, "2026-253", "20260910" and "2026-W37-4" as dates, and drops the time off
  # "2026-09-10T23:59:00-07:00" — all real dates nobody sent. The format is checked BEFORE
  # parsing for that reason, not as a nicety.
  module IsoDate
    FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

    # @param value [Object] anything; `to_s` makes `?date[]=x` fail the format instead of
    #   raising `TypeError`, and lets a `Date` round-trip
    # @return [Date, nil]
    def self.parse(value)
      text = value.to_s
      Date.iso8601(text) if text.match?(FORMAT)
    # FORMAT bounds the input to ten ASCII characters, so the only failure left is an
    # impossible calendar date ("2026-02-31"). Loosen FORMAT and this rescue has to widen
    # too: the `date` gem's 128-character anti-ReDoS cut raises a bare ArgumentError, which
    # is not a Date::Error.
    rescue Date::Error
      nil
    end
  end
end
