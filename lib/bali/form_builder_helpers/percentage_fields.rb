module Bali
  module FormBuilderHelpers
    module PercentageFields
      def percentage_field_group(method, options = {})
        options.with_defaults!(
          placeholder: 0,
          addon_right: tag.span('%', class: 'button is-static'),
          step: '0.01',
          pattern_type: :number_with_commas
        )

        FieldGroupWrapper.render @template, self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end