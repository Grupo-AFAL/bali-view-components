# frozen_string_literal: true

module Bali
  module Calendar
    # The calendar and its header both take their start date and period straight off a
    # query string, so both have to survive whatever a visitor types there.
    module Normalization
      private

      # `?start_date=zzz` needs no session and no knowledge of the app, so an unrescued
      # Date.parse here is a 500 any visitor can trigger. Fall back to today.
      #
      # Both rescued classes are real. Date.parse raises Date::Error (an ArgumentError)
      # for a string it cannot read, and TypeError for an argument that is not a string
      # at all — which is what `?start_date[]=1` produced against the header, the one
      # call site that handed the raw value over without #to_s.
      def normalize_date(value)
        return Date.current if value.blank?
        return value if value.is_a?(Date)

        Date.parse(value.to_s)
      rescue ArgumentError, TypeError
        Date.current
      end

      # Compared as strings rather than interned with #to_sym: `?period[]=1` gives an
      # Array, which has no #to_sym, and turning visitor input into symbols to throw
      # them away again is not worth it for a three-element list.
      def normalize_period(value)
        Component::PERIODS.find { |period| period.to_s == value.to_s } || :month
      end
    end
  end
end
