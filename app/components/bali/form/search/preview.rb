# frozen_string_literal: true

module Bali
  module Form
    module Search
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic search input field with DaisyUI styling and a submit button.
        def default
          render_with_template(
            template: 'bali/form/search/previews/default',
            locals: { model: form_record }
          )
        end

        # @label Custom Placeholder
        # Shows search field with a custom placeholder text.
        def custom_placeholder
          render_with_template(
            template: 'bali/form/search/previews/custom_placeholder',
            locals: { model: form_record }
          )
        end

        # @label Custom Button Style
        # Shows search field with a custom button style (using addon_class option).
        def custom_button_style
          render_with_template(
            template: 'bali/form/search/previews/custom_button_style',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the search field with validation error styling.
        def with_errors
          form_record.errors.add(:text, :blank)

          render_with_template(
            template: 'bali/form/search/previews/with_errors',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
