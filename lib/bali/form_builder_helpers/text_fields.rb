# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module TextFields
      def text_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end
