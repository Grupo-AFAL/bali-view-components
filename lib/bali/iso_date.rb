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
    #   raising `TypeError`
    # @return [Date, nil]
    def self.parse(value)
      text = value.to_s
      Date.iso8601(text) if text.match?(FORMAT)
    # Date::Error alone: FORMAT keeps input far below the date gem's 128-char cut, whose
    # ArgumentError is not a Date::Error. Loosen FORMAT, widen this.
    rescue Date::Error
      nil
    end
  end
end
