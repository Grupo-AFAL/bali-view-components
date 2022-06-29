# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CurrencyFields
      def currency_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 0,
          addon_left: tag.span('$', class: 'button is-static'),
          step: '0.01',
          pattern_type: :number_with_commas
        )

        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end
