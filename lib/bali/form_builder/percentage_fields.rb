# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module PercentageFields
      def percentage_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 0,
          addon_right: tag.span('%', class: 'button is-static'),
          step: '0.01',
        )

        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          number_field(method, options)
        end
      end
    end
  end
end
