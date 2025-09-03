# frozen_string_literal: true

module Bali
  module Types
    class TimePeriodValue < ActiveRecord::Type::Value
      def cast(value)
        if value.is_a?(String) && value.match?('..')
          start_range, end_range = value.split('..')
          start_range..end_range
        else
          Bali::Types::DateRangeValue.new.cast(value)
        end
      end

      def serialize(value)
        value
      end
    end
  end
end
