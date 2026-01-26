# frozen_string_literal: true

module Bali
  module Form
    module Password
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic password input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/password/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the password field with validation error styling.
        def with_errors
          form_record.errors.add(:password, 'is too short')

          render_with_template(
            template: 'bali/form/password/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Addons
        # Shows password field with a show/hide button using DaisyUI join pattern.
        def with_addons
          render_with_template(
            template: 'bali/form/password/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows password field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/password/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
