# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module SearchFields
      def search_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 'Search...',
          addon_right: tag.button(
            @template.render(Bali::Icon::Component.new('search')),
            type: 'submit',
            class: options.delete(:addon_class) || 'button is-info'
          )
        )

        FieldGroupWrapper.render @template, self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end
