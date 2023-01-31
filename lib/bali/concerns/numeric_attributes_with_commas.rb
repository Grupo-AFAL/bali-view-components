# frozen_string_literal: true

# Complements the `percentage_field_group` and `currency_field_group` methods
# by removing the `commas` before saving the value to the DB.
module Bali
  module Concerns
    module NumericAttributesWithCommas
      extend ActiveSupport::Concern

      class_methods do
        def percentage_attribute(name)
          define_numeric_attribute_setter(name)
          define_numeric_attribute_getter(name)
        end

        def currency_attribute(name)
          define_numeric_attribute_setter(name)
          define_numeric_attribute_getter(name)
        end

        def define_numeric_attribute_setter(name)
          define_method name do
            return read_attribute(name.to_sym) if respond_to?(:read_attribute)

            instance_variable_get("@#{name}")
          end
        end

        def define_numeric_attribute_getter(name)
          define_method "#{name}=" do |value|
            value = value.gsub(',', '').to_d if value.is_a?(String)

            if respond_to?(:write_attribute)
              write_attribute(name.to_sym, value)
            else
              instance_variable_set("@#{name}", value)
            end
          end
        end
      end
    end
  end
end
