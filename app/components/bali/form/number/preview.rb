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

        # @label Delimited (live thousands separator)
        # `delimited: true` groups the thousands on every keystroke, so a long
        # amount reads 1,500,200.75 while it is being typed. It costs the field
        # its native type — a `number` input cannot hold a delimiter — so the
        # input is `text` with an `inputmode` and a locale-aware `pattern`, and
        # `min`/`max`/`step` are dropped because the browser enforces none of
        # them there.
        #
        # The value below arrives from the server as the machine number
        # `1500200.75` and is grouped on connect.
        def delimited
          form_record.number = 1_500_200.75

          render_with_template(
            template: 'bali/form/number/previews/delimited',
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
