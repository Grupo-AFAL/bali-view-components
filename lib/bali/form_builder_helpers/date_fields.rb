module Bali
  module FormBuilderHelpers
    module DateFields
      def date_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          date_field(method, options)
        end
      end

      alias date_select_group date_field_group
    end
  end
end