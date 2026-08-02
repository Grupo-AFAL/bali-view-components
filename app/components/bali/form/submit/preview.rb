# frozen_string_literal: true

module Bali
  module Form
    module Submit
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic submit button with primary variant.
        def default
          render_with_template(
            template: 'bali/form/submit/previews/default',
            locals: { model: form_record }
          )
        end

        # @label Variants
        # Shows all available button variants: primary, secondary, accent, success, warning, error, ghost.
        def variants
          render_with_template(
            template: 'bali/form/submit/previews/variants',
            locals: { model: form_record }
          )
        end

        # @label Sizes
        # Shows all available button sizes: xs, sm, md (default), lg.
        def sizes
          render_with_template(
            template: 'bali/form/submit/previews/sizes',
            locals: { model: form_record }
          )
        end

        # @label Submit Group
        # Shows the submit_group helper: the actions row, with the cancel
        # control beside the submit button.
        def submit_group
          render_with_template(
            template: 'bali/form/submit/previews/submit_group',
            locals: { model: form_record }
          )
        end

        # @label Modal Actions
        # Shows submit_group for modal forms with Cancel and Save buttons.
        # The cancel button uses a button element (not link) with modal#close action.
        def modal_actions
          render_with_template(
            template: 'bali/form/submit/previews/modal_actions',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
