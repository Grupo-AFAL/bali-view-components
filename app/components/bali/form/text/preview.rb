# frozen_string_literal: true

module Bali
  module Form
    module Text
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic text input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the text field with validation error styling.
        def with_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Addons
        # Shows text field with left and right addons using DaisyUI join pattern.
        def with_addons
          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Addons and Errors
        # Shows text field with addons and validation error.
        def with_addons_and_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows text field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/text/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
