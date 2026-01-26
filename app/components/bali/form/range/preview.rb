# frozen_string_literal: true

module Bali
  module Form
    module Range
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Basic range slider with default settings.
        def default
          render_with_template(
            template: 'bali/form/range/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Colors
        # Range slider with different color variants.
        # @param color select { choices: [primary, secondary, accent, success, warning, info, error] }
        def with_colors(color: :primary)
          render_with_template(
            template: 'bali/form/range/previews/with_colors',
            locals: { model: form_record, color: color.to_sym }
          )
        end

        # @label With Sizes
        # Range slider with different size variants.
        # @param size select { choices: [xs, sm, md, lg] }
        def with_sizes(size: :md)
          render_with_template(
            template: 'bali/form/range/previews/with_sizes',
            locals: { model: form_record, size: size.to_sym }
          )
        end

        # @label With Tick Marks
        # Range slider with tick marks showing values.
        def with_ticks
          render_with_template(
            template: 'bali/form/range/previews/with_ticks',
            locals: { model: form_record }
          )
        end

        # @label With Custom Labels
        # Range slider with custom tick labels.
        def with_custom_labels
          render_with_template(
            template: 'bali/form/range/previews/with_custom_labels',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
