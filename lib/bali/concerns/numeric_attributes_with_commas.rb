# frozen_string_literal: true

# The server half of `currency_group` and `percentage_group`: those
# render a text input so the user can type a formatted amount, and this turns
# what they typed back into a number.
#
# Both separators come from the active locale, which is the whole point. The
# old implementation deleted commas and nothing else, so it was correct in
# English and silently wrong everywhere the comma is the *decimal* separator:
# a Spanish user typing `1.234,56` — the correct way to write it — was stored
# as `1.23456`. No exception, no validation error, just a number four orders of
# magnitude too small.
module Bali
  module Concerns
    module NumericAttributesWithCommas
      extend ActiveSupport::Concern

      # Rails' own English defaults, so a host without rails-i18n keeps exactly
      # the behaviour it had before.
      def self.to_decimal(value)
        delimiter = I18n.t("number.format.delimiter", default: ",")
        separator = I18n.t("number.format.separator", default: ".")

        value.delete(delimiter).tr(separator, ".").to_d
      end

      class_methods do
        def percentage_attribute(name)
          define_numeric_attribute_setter(name)
          define_numeric_attribute_getter(name)
        end

        def currency_attribute(name)
          define_numeric_attribute_setter(name)
          define_numeric_attribute_getter(name)
        end

        def define_numeric_attribute_getter(name)
          define_method name do
            return read_attribute(name.to_sym) if respond_to?(:read_attribute)

            instance_variable_get("@#{name}")
          end
        end

        def define_numeric_attribute_setter(name)
          define_method "#{name}=" do |value|
            value = NumericAttributesWithCommas.to_decimal(value) if value.is_a?(String)

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
