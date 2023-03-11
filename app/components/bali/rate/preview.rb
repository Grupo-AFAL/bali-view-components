# frozen_string_literal: true

module Bali
  module Rate
    class Preview < ApplicationViewComponentPreview
      # Default Rate
      # --------------
      # Renders radio buttons displayed as stars
      # @param value [Integer] select [1, 2, 3, 4, 5]
      # @param size select [small, medium, large]
      def default(value: 1, size: :medium)
        render Rate::Component.new(
          form: form_builder,
          method: :rating,
          value: value,
          scale: 1..5,
          size: size
        )
      end

      # Auto submit on click
      # --------------
      # Renders submit buttons as stars
      # @param value [Integer] select [1, 2, 3, 4, 5]
      # @param size select [small, medium, large]
      def auto_submit(value: 1, size: :medium)
        render Rate::Component.new(
          form: form_builder,
          method: :rating,
          value: value,
          scale: 1..5,
          size: size,
          auto_submit: true
        )
      end

      # Readonly for display purposes
      # --------------
      # Renders stars only
      # @param value [Integer] select [1, 2, 3, 4, 5]
      # @param size select [small, medium, large]
      def readonly(value: 1, size: :medium)
        render Rate::Component.new(
          value: value,
          scale: 1..5,
          size: size,
          readonly: true
        )
      end

      private

      def form_builder
        view_context = ActionController::Base.new.view_context
        Bali::FormBuilder.new('movie', Movie.new, view_context, {})
      end
    end
  end
end
