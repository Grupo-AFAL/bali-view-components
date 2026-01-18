# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    alias rails_file_field file_field

    module FileFields
      INPUT_CLASS = 'file-input'
      WRAPPER_CLASS = 'flex items-center gap-2'
      FILENAME_CLASS = 'truncate text-base-content/70'
      CTA_CLASS = 'btn btn-ghost btn-sm gap-2'
      LABEL_CLASS = 'cursor-pointer'
      DEFAULT_ICON = 'upload'

      def file_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          file_field(method, options)
        end
      end

      def file_field(method, options = {})
        field_helper(
          method,
          custom_file_field(method, field_options(method, options)),
          options
        )
      end

      private

      def custom_file_field(method, options = {})
        choose_file_text = extract_option(options, :choose_file_text) { default_choose_text }
        non_selected_text = extract_option(options, :non_selected_text) do
          default_non_selected_text
        end
        file_icon_name = extract_option(options, :icon) || DEFAULT_ICON
        multiple = options.fetch(:multiple, false)
        file_class = extract_option(options, :file_class)

        input_options = build_input_options(options)

        @template.content_tag(:div, wrapper_options(non_selected_text, multiple, file_class)) do
          @template.content_tag(:label, class: LABEL_CLASS) do
            rails_file_field(method, input_options) +
              file_cta(file_icon_name, choose_file_text) +
              filename_display(non_selected_text)
          end
        end
      end

      def extract_option(options, key, &block)
        if options.key?(key)
          options.delete(key)
        elsif block
          block.call
        end
      end

      def build_input_options(options)
        opts = prepend_class_name(options, INPUT_CLASS)
        opts = prepend_action(opts, 'file-input#onChange')
        prepend_data_attribute(opts, :file_input_target, :input)
      end

      def wrapper_options(non_selected_text, multiple, file_class)
        {
          class: class_names(WRAPPER_CLASS, file_class => file_class.present?),
          data: {
            controller: 'file-input',
            file_input_non_selected_text_value: non_selected_text,
            file_input_multiple_value: multiple
          }
        }
      end

      def filename_display(non_selected_text)
        @template.content_tag(
          :span,
          non_selected_text,
          class: FILENAME_CLASS,
          data: { 'file-input-target': 'value' }
        )
      end

      def file_cta(icon_name, label_text)
        @template.content_tag(:span, class: CTA_CLASS) do
          icon = @template.render(Bali::Icon::Component.new(icon_name))
          label = label_text && @template.content_tag(:span, label_text)
          icon + (label || ''.html_safe)
        end
      end

      def default_choose_text
        I18n.t('bali.form_builder.file.choose_file')
      end

      def default_non_selected_text
        I18n.t('bali.form_builder.file.no_file_selected')
      end
    end
  end
end
