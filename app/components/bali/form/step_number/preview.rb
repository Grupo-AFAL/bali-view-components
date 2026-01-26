# frozen_string_literal: true

module Bali
  module Form
    module StepNumber
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Basic step number input with increment/decrement buttons.
        def default
          render_with_template(
            template: 'bali/form/step_number/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Constraints
        # Step number input with min, max, and step constraints.
        # The Stimulus controller will enforce these limits.
        def with_constraints
          render_with_template(
            template: 'bali/form/step_number/previews/with_constraints',
            locals: { model: form_record }
          )
        end

        # @label Disabled
        # Disabled step number input where buttons are non-interactive.
        def disabled
          render_with_template(
            template: 'bali/form/step_number/previews/disabled',
            locals: { model: form_record }
          )
        end

        # @label With Custom Button Style
        # Step number input with custom button styling (btn-primary).
        def with_custom_buttons
          render_with_template(
            template: 'bali/form/step_number/previews/with_custom_buttons',
            locals: { model: form_record }
          )
        end

        # @label With Field Group
        # Step number input wrapped in a field group with label.
        def with_field_group
          render_with_template(
            template: 'bali/form/step_number/previews/with_field_group',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
