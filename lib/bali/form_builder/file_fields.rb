# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    alias rails_file_field file_field
    module FileFields
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
        options.with_defaults!(
          choose_file_text: I18n.t('bali.form_builder.file.choose_file'),
          non_selected_text: I18n.t('bali.form_builder.file.no_file_selected'),
          icon: 'upload',
          multiple: false
        )

        options = prepend_class_name(options, 'file-input')
        options = prepend_action(options, 'file-input#onChange')
        options = prepend_data_attribute(options, :file_input_target, :input)

        choose_file_text = options.delete(:choose_file_text)
        non_selected_text = options.delete(:non_selected_text)
        file_icon_name = options.delete(:icon)

        @template.content_tag(:div, wrapper_options(non_selected_text, options)) do
          @template.content_tag(:label, class: 'cursor-pointer') do
            rails_file_field(method, options) +
              file_cta(file_icon_name, choose_file_text) +
              filename(non_selected_text)
          end
        end
      end

      def wrapper_options(non_selected_text, options)
        file_class = options.delete(:file_class)

        {
          class: ['flex items-center gap-2', file_class].compact.join(' '),
          data: {
            controller: 'file-input',
            file_input_non_selected_text_value: non_selected_text,
            file_input_multiple_value: options[:multiple]
          }
        }
      end

      def filename(non_selected_text)
        @template.content_tag(
          :span, non_selected_text, class: 'truncate text-base-content/70',
                                    data: { 'file-input-target': 'value' }
        )
      end

      def file_cta(file_icon_name, choose_file_text)
        @template.content_tag(:span, class: 'btn btn-ghost btn-sm gap-2') do
          file_icon = @template.render(Bali::Icon::Component.new(file_icon_name))

          file_label = if choose_file_text == false
                         ''
                       else
                         @template.content_tag(:span, choose_file_text)
                       end

          file_icon + file_label
        end
      end
    end
  end
end
