# frozen_string_literal: true

module Bali
  module Form
    module Select
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Native HTML select element with DaisyUI styling.
        # Uses `select select-bordered w-full` classes.
        def default
          render_with_template(
            template: 'bali/form/select/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows validation error styling with `input-error` class.
        def with_errors
          form_record.errors.add(:status, 'must be selected')

          render_with_template(
            template: 'bali/form/select/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Displays helper text below the select.
        def with_help_text
          render_with_template(
            template: 'bali/form/select/previews/with_help_text',
            locals: { model: form_record }
          )
        end

        # @label With Blank Option
        # Include prompt option using the `include_blank` option.
        def with_blank_option
          render_with_template(
            template: 'bali/form/select/previews/with_blank_option',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
