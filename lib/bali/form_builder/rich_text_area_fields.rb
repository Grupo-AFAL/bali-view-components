# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RichTextAreaFields
      # The caption stays a `<legend>` and the editor points an `aria-labelledby`
      # at it instead: `<trix-editor>` is a custom element, and `<label for>` only
      # names *labelable* elements, so a `for` here is markup the browser drops on
      # the floor. `aria-labelledby` works on any element.
      def rich_text_area_group(method, options = {})
        labelled = caption_id(method, options)
        editor_options = labelled ? options.merge("aria-labelledby": labelled) : options

        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false)
        ) do
          rich_text_area(method, editor_options)
        end
      end

      def rich_text_area(method, options = {})
        max_attachments_size = options.dig(:attachments, :max_size) || 1
        default_error_msg = "Attachments must not exceed #{max_attachments_size}MB"
        # Named apart from `HtmlUtils#error_message`, which renders the field's
        # validation error: this one is the attachment-size warning Trix shows.
        attachments_error_message = options.dig(:attachments, :error_message) || default_error_msg

        # ActionText writes its direct-upload URLs into `:data` in place, so the
        # nested hash has to be ours before the tag helper ever sees it.
        opts = dup_options(options).with_defaults(
          'data-controller': "trix-attachments",
          'data-trix-attachments-max-size-value': max_attachments_size,
          'data-trix-attachments-error-message-value': attachments_error_message
        )
        opts[:class] = "trix-content #{options[:class]}".strip

        field_helper(method, super(method, field_options(method, opts)), options)
      end
    end
  end
end
