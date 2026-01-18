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

        # @label With Character Counter
        # Shows textarea with character counter. Displays current character count.
        # Use `char_counter: true` for simple counter, or `char_counter: { max: 500 }`
        # to show a maximum limit.
        def with_char_counter
          render_with_template(
            template: 'bali/form/text_area/previews/with_char_counter',
            locals: { model: form_record }
          )
        end

        # @label With Auto Grow
        # Textarea automatically expands as you type more content.
        # The height adjusts to fit the content, eliminating the need for scrolling.
        def with_auto_grow
          render_with_template(
            template: 'bali/form/text_area/previews/with_auto_grow',
            locals: { model: form_record }
          )
        end

        # @label With Both Features
        # Combines character counter with maximum limit and auto-grow functionality.
        def with_both_features
          render_with_template(
            template: 'bali/form/text_area/previews/with_both_features',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
