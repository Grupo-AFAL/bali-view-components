module Bali
  module FormBuilderHelpers
    module EmailFields
      def email_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          email_field(method, options)
        end
      end

      def email_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end