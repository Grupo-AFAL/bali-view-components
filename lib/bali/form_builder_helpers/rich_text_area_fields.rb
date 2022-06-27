module Bali
  module FormBuilderHelpers
    module RichTextAreaFields
      def rich_text_area_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          rich_text_area(method, options)
        end
      end

      def rich_text_area(method, options = {})
        max_attachments_size = options.dig(:attachments, :max_size) || 1
        default_error_msg = "Attachments must not exceed #{max_attachments_size}MB"
        error_message = options.dig(:attachments, :error_message) || default_error_msg

        options.with_defaults!(
          'data-controller': 'trix-attachments',
          'data-trix-attachments-max-size-value': max_attachments_size,
          'data-trix-attachments-error-message-value': error_message
        )

        options[:class] = "trix-content #{options[:class]}".strip
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end