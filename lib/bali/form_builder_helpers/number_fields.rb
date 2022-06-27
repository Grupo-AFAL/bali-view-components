module Bali
  module FormBuilderHelpers
    module NumberFields
      def number_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          number_field(method, options)
        end
      end
    end
  end
end