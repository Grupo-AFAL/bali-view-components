# frozen_string_literal: true

module Bali
  module Rate
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Uses DaisyUI's native rating component with star-shaped radio buttons.
      # Integrates with Rails form builders for form submissions.
      # @param value select [1, 2, 3, 4, 5]
      # @param size select [xs, sm, md, lg]
      # @param color select [warning, primary, secondary, accent, success, error, info]
      def default(value: 3, size: :md, color: :warning)
        render Rate::Component.new(
          form: form_builder,
          method: :rating,
          value: value,
          size: size.to_sym,
          color: color.to_sym
        )
      end

      # @label Auto Submit
      # Renders submit buttons instead of radio inputs. Clicking a star
      # immediately submits the form with that rating value.
      # @param value select [1, 2, 3, 4, 5]
      # @param size select [xs, sm, md, lg]
      # @param color select [warning, primary, secondary, accent, success, error, info]
      def auto_submit(value: 3, size: :md, color: :warning)
        render Rate::Component.new(
          form: form_builder,
          method: :rating,
          value: value,
          size: size.to_sym,
          color: color.to_sym,
          auto_submit: true
        )
      end

      # @label Readonly
      # Display-only mode for showing existing ratings. Uses disabled
      # inputs with no form integration.
      # @param value select [1, 2, 3, 4, 5]
      # @param size select [xs, sm, md, lg]
      # @param color select [warning, primary, secondary, accent, success, error, info]
      def readonly(value: 4, size: :md, color: :warning)
        render Rate::Component.new(
          value: value,
          size: size.to_sym,
          color: color.to_sym,
          readonly: true
        )
      end

      # @label All Sizes
      # Comparison of all available sizes from extra-small to large.
      def all_sizes
        render_with_template
      end

      # @label All Colors
      # Comparison of all available color variants.
      def all_colors
        render_with_template
      end

      private

      def form_builder
        view_context = ActionController::Base.new.view_context
        Bali::FormBuilder.new('movie', Movie.new, view_context, {})
      end
    end
  end
end
