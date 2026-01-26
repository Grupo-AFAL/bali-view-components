# frozen_string_literal: true

module Bali
  module Form
    module Email
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic email input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/email/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the email field with validation error styling.
        def with_errors
          form_record.errors.add(:email, :invalid)

          render_with_template(
            template: 'bali/form/email/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Addons
        # Shows email field with left and right addons using DaisyUI join pattern.
        def with_addons
          render_with_template(
            template: 'bali/form/email/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Addons and Errors
        # Shows email field with addons and validation error.
        def with_addons_and_errors
          form_record.errors.add(:email, :invalid)

          render_with_template(
            template: 'bali/form/email/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows email field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/email/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
