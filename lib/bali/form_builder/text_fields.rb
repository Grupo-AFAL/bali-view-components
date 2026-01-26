# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # TextFields provides the text_field_group helper.
    #
    # Note: The `text_field` method is defined in SharedUtils since it's the
    # foundational text input that other field types build upon. This module
    # only provides the _group wrapper variant.
    module TextFields
      def text_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          text_field(method, options)
        end
      end
    end
  end
end
