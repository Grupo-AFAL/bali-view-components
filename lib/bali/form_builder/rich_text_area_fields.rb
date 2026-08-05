# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RichTextAreaFields
      # The caption stays a `<legend>` and the editor points an `aria-labelledby`
      # at it instead: `<trix-editor>` is a custom element, and `<label for>` only
      # names *labelable* elements, so a `for` here is markup the browser drops on
      # the floor. `aria-labelledby` works on any element.
      def rich_text_area_group(method, **options)
        labelled = caption_id(method, options)
        editor_options = labelled ? options.merge("aria-labelledby": labelled) : options

        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false)
        ) do
          rich_text_area_field(method, editor_options)
        end
      end

      # The canonical name, and the only one a caller should reach for.
      def rich_text_area_field(method, options = {})
        rich_text_area(method, options)
      end

      # Unlike `text_area` and `time_zone_select`, this override cannot hand its
      # body to the `<type>_field` name: ActionText installs `rich_text_area` on
      # `ActionView::Helpers::FormBuilder` from an initializer, so it does not
      # exist yet when this file is loaded and there is nothing to alias. The
      # implementation therefore stays where `super` can still reach it, and it
      # is `rich_text_area_field` that delegates rather than the other way round.
      def rich_text_area(method, options = {})
        max_attachments_size = options.dig(:attachments, :max_size) || 1
        default_error_msg = "Attachments must not exceed #{max_attachments_size}MB"
        # Named apart from `HtmlUtils#error_message`, which renders the field's
        # validation error: this one is the attachment-size warning Trix shows.
        attachments_error_message = options.dig(:attachments, :error_message) || default_error_msg

        # ActionText writes its direct-upload URLs into `:data` in place, so the
        # nested hash has to be ours before the tag helper ever sees it. The
        # control-only keys come off here rather than at the end, because
        # `field_options` still has to read the addon and pattern keys out of
        # this very hash.
        opts = dup_options(options).except(*HtmlUtils::CONTROL_ONLY_OPTIONS).with_defaults(
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
