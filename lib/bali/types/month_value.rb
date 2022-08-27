module Bali
  module Types
    class MonthValue < ActiveRecord::Type::String
      def cast(value)
        # Rails.logger.info "\n\ncast: #{value}, #{value.class}\n"
        return if value.blank?

        # value.concat('-01') if value.is_a?(String) && value.length == 7 # YYYY-MM

        # Rails.logger.info "cast 2: #{value}, #{value.class}\n\n"

        Date.parse(normalize_date(value))
      end

      def serialize(value)
        # Rails.logger.info "\n\nSerialize: #{value}, #{value.class}\n"

        # value.concat('-01') if value.is_a?(String) && value.length == 7 # YYYY-MM

        # Rails.logger.info "Serialize2: #{value}, #{value.class}\n\n"
        normalize_date(value)
      end

      private 

      def normalize_date(value)
        value.concat('-01') if value.is_a?(String) && value.length == 7
        value
      end
    end
  end
end
