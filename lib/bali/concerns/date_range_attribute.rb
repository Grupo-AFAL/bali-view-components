# frozen_string_literal: true

# Allows to define date range attributes.
# It will convert '2023-01-01 to 2023-01-10' to a Range
#
# Example:
#
# class Model
#   include ActiveModel::Attributes
#   include Bali::Concerns::DateRangeAttribute
#
#   date_range_attribute :date_range, default: Time.zone.now.all_day
#
# end
#

module Bali
  module Concerns
    module DateRangeAttribute
      extend ActiveSupport::Concern

      class_methods do
        def date_range_attribute(name, default: nil, start_attribute: nil, end_attribute: nil)
          attribute(name, default: default)

          override_setter(name, start_attribute, end_attribute)
          override_getter(name, start_attribute, end_attribute)
        end

        def override_setter(name, start_attribute, end_attribute)
          define_method "#{name}=" do |value|
            return if value.blank?

            range = normalize_date_range(value)
            super(range)

            return unless start_attribute && end_attribute && range

            assign_attributes(start_attribute => range.first, end_attribute => range.last)
          end
        end

        def override_getter(name, start_attribute, end_attribute)
          define_method name do
            return attributes[name.to_s] if start_attribute.blank? && end_attribute.blank?

            range_start = attributes[start_attribute.to_s]
            range_end = attributes[end_attribute.to_s]

            range_start..range_end if range_start && range_end
          end
        end
      end

      private

      def date_range_separator
        { en: ' to ', es: 'a ' }[I18n.locale]
      end

      def normalize_date_range(range)
        return range unless range.is_a? String

        result = range.split(date_range_separator)

        # Searching in a day instead of date range
        result = [result.first, result.first] if result.size == 1

        result[0] = Time.zone.parse(result.first).beginning_of_day
        result[1] = Time.zone.parse(result.last).end_of_day
        result[0]..result[1]
      end
    end
  end
end
