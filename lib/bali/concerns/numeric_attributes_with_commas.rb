# frozen_string_literal: true

module Bali
  module Concerns
    module NumericAttributesWithCommas
      extend ActiveSupport::Concern

      class_methods do
        def percentage_attribute(name)
          numeric_attribute_with_commas(name)
        end

        def currency_attribute(name)
          numeric_attribute_with_commas(name)
        end

        def numeric_attribute_with_commas(name)
          define_method name do
            read_attribute(name.to_sym)
          end

          define_method "#{name}=" do |value|
            value = value.gsub(',', '') if value.is_a?(String)

            write_attribute(name.to_sym, value)
          end
        end
      end
    end
  end
end
