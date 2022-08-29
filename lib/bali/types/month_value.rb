# frozen_string_literal: true

module Bali
  module Types
    class MonthValue < ActiveRecord::Type::String
      def cast(value)
        return if value.blank?

        Date.parse(normalize_date(value))
      end

      def serialize(value)
        normalize_date(value)
      end

      private

      def normalize_date(value)
        value += '-01' if value.is_a?(String) && value.length == 7
        value
      end
    end
  end
end
