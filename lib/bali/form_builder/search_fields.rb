# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SearchFields
      def search_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 'Search...',
          addon_right: tag.button(
            @template.render(Bali::Icon::Component.new('search')),
            type: 'submit',
            class: options.delete(:addon_class) || 'btn btn-info'
          )
        )

        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end
