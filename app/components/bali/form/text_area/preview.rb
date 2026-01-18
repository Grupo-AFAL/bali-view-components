# frozen_string_literal: true

module Bali
  module Form
    module TextArea
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # @param rows number
        # @param placeholder text
        # @param char_counter toggle
        # @param max_length number
        # @param auto_grow toggle
        # Interactive preview with all textarea options.
        def default(rows: 3, placeholder: 'Enter text...', char_counter: false,
                    max_length: 0, auto_grow: false)
          render_with_template(
            template: 'bali/form/text_area/previews/default',
            locals: {
              model: form_record,
              rows: rows,
              placeholder: placeholder,
              char_counter: char_counter,
              max_length: max_length.to_i,
              auto_grow: auto_grow
            }
          )
        end

        # @label With Errors
        # Shows the textarea with validation error styling.
        def with_errors
          form_record.errors.add(:text, :blank)

          render_with_template(
            template: 'bali/form/text_area/previews/default',
            locals: {
              model: form_record,
              rows: 3,
              placeholder: 'Enter text...',
              char_counter: false,
              max_length: 0,
              auto_grow: false
            }
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

        # @label Character Counter Example
        # Example showing character counter with 280 character limit (Twitter-style).
        def char_counter_example
          render_with_template(
            template: 'bali/form/text_area/previews/char_counter_example',
            locals: { model: form_record }
          )
        end

        # @label Auto Grow Example
        # Textarea that automatically expands as you type.
        def auto_grow_example
          render_with_template(
            template: 'bali/form/text_area/previews/auto_grow_example',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
