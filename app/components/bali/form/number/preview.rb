# frozen_string_literal: true

module Bali
  module Form
    module Number
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic number input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/number/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the number field with validation error styling.
        def with_errors
          form_record.errors.add(:budget, 'must be greater than zero')

          render_with_template(
            template: 'bali/form/number/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Currency Addon
        # Shows number field with a currency symbol addon using DaisyUI join pattern.
        def with_currency_addon
          render_with_template(
            template: 'bali/form/number/previews/with_currency_addon',
            locals: { model: form_record }
          )
        end

        # @label With Min/Max/Step
        # Shows number field with min, max, and step constraints.
        def with_constraints
          render_with_template(
            template: 'bali/form/number/previews/with_constraints',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows number field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/number/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
