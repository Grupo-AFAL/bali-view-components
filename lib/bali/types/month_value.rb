# frozen_string_literal: true

module Bali
  module Types
    class MonthValue < ActiveRecord::Type::String
      # Returns nil for anything it cannot read. The cast runs on assignment, before any
      # validation, so raising here was a 500 no model could defend against.
      def cast(value)
        return if value.blank?

        Bali::IsoDate.parse(normalize_date(value))
      end

      def serialize(value)
        return value if value.blank?

        cast(value)&.iso8601
      end

      private

      def normalize_date(value)
        value += "-01" if value.is_a?(String) && value.length == 7
        value
      end
    end
  end
end
