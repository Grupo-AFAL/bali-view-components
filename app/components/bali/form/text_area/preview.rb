# frozen_string_literal: true

module Bali
  module Form
    module TextArea
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic textarea field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/text_area/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the textarea with validation error styling.
        def with_errors
          form_record.errors.add(:text, :blank)

          render_with_template(
            template: 'bali/form/text_area/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows textarea with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/text_area/previews/with_help_text',
            locals: { model: form_record }
          )
        end

        # @label With Custom Size
        # Shows textarea with custom rows and CSS sizing.
        def with_custom_size
          render_with_template(
            template: 'bali/form/text_area/previews/with_custom_size',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
