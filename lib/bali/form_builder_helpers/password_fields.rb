# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module PasswordFields
      def password_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          password_field(method, options)
        end
      end

      def password_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end
