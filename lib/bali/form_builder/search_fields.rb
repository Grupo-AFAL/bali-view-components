# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SearchFields
      DEFAULT_BUTTON_CLASSES = 'btn btn-info'

      def search_field_group(method, options = {})
        addon_class = options.delete(:addon_class) || DEFAULT_BUTTON_CLASSES

        options.with_defaults!(
          placeholder: I18n.t('bali.form_builder.search.placeholder'),
          addon_right: search_addon(addon_class)
        )

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          text_field(method, options)
        end
      end

      private

      def search_addon(button_class)
        tag.button(
          @template.render(Bali::Icon::Component.new('search')),
          type: 'submit',
          class: button_class
        )
      end
    end
  end
end
