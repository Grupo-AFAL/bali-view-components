# frozen_string_literal: true

module Bali
  module Types
    class MonthValue < ActiveRecord::Type::String
      # Never raises: cast runs on assignment, before any validation could catch it.
      def cast(value)
        return if value.blank?
        return value.to_date if value.acts_like?(:date) || value.acts_like?(:time)

        Bali::IsoDate.parse(normalize_date(value))
      end

      def serialize(value)
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
