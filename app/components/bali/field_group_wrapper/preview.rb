# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Preview < ApplicationViewComponentPreview
      # @param show_tooltip toggle
      # @param label_text text
      def default(show_tooltip: false, label_text: nil)
        render_with_template(
          template: 'bali/field_group_wrapper/previews/default',
          locals: {
            model: form_record,
            show_tooltip: show_tooltip,
            label_text: label_text
          }
        )
      end

      # Demonstrates a hidden field where the label is not rendered.
      def hidden_field
        render_with_template(
          template: 'bali/field_group_wrapper/previews/hidden_field',
          locals: { model: form_record }
        )
      end

      # Demonstrates explicitly hiding the label with `label: false`.
      def without_label
        render_with_template(
          template: 'bali/field_group_wrapper/previews/without_label',
          locals: { model: form_record }
        )
      end

      # Shows custom CSS classes applied to the wrapper.
      def with_custom_classes
        render_with_template(
          template: 'bali/field_group_wrapper/previews/with_custom_classes',
          locals: { model: form_record }
        )
      end
    end
  end
end
