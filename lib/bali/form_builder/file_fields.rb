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
        options = prepend_class_name(options, 'file-input')
        options = prepend_action(options, 'file-input#onChange')

        choose_file_text = if options.key?(:choose_file_text)
                             options.delete(:choose_file_text)
                           else
                             'Choose file'
                           end

        non_selected_text = if options.key?(:non_selected_text)
                              options.delete(:non_selected_text)
                            else
                              'No file selected'
                            end

        file_class = options.delete(:file_class)
        file_icon_name = options.delete(:icon) || 'upload'

        @template.content_tag(:div, wrapper_options(non_selected_text, file_class)) do
          @template.content_tag(:label, class: 'file-label') do
            rails_file_field(method, options) +
              file_cta(file_icon_name, choose_file_text) +
              filename(non_selected_text)
          end
        end
      end

      def wrapper_options(non_selected_text, file_class)
        {
          class: "file has-name #{file_class}".strip,
          data: {
            controller: 'file-input',
            'file-input-non-selected-text-value': non_selected_text
          }
        }
      end

      def filename(non_selected_text)
        @template.content_tag(
          :span, non_selected_text, class: 'file-name', data: { 'file-input-target': 'value' }
        )
      end

      def file_cta(file_icon_name, choose_file_text)
        icon_class = class_names('file-icon', 'empty-text': !choose_file_text)

        @template.content_tag(:span, class: 'file-cta') do
          file_icon = @template.content_tag(:span, class: icon_class) do
            @template.render(Bali::Icon::Component.new(file_icon_name))
          end

          file_label = if choose_file_text == false
                         ''
                       else
                         @template.content_tag(:span, choose_file_text, class: 'file-label')
                       end

          file_icon + file_label
        end
      end
    end
  end
end
