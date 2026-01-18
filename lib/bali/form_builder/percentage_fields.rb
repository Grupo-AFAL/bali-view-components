# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module PercentageFields
      def percentage_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 0,
          addon_right: percentage_addon,
          step: '0.01',
          pattern_type: :number_with_commas
        )

        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          text_field(method, options)
        end
      end

      private

      def percentage_addon
        tag.span('%', class: HtmlUtils::ADDON_CLASSES)
      end
    end
  end
end
