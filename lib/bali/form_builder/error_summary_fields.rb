# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module ErrorSummaryFields
      # Renders a summary of all validation errors for the form's model.
      #
      # @param title [String, nil] Optional title displayed above the error list
      # @param options [Hash] Additional options passed to the component
      # @return [String] The rendered error summary HTML, or empty string if no errors
      #
      # @example Basic usage
      #   <%= f.error_summary %>
      #
      # @example With custom title
      #   <%= f.error_summary(title: "Please fix the following errors:") %>
      #
      def error_summary(title: nil, **)
        return ''.html_safe unless object&.errors&.any?

        @template.render(
          Bali::Form::Errors::Component.new(
            model: object,
            title: title,
            **
          )
        )
      end
    end
  end
end
