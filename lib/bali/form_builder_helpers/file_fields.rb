# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module FileFields
      def file_field_group(method, options = {})
        options.with_defaults!(
          class: 'file-input',
          data: { action: 'file-input#onChange' }
        )

        choose_file_text = options.delete(:choose_file_text) || 'Choose file'
        non_selected_text = options.delete(:non_selected_text) || 'No file selected'
        file_icon_name = options.delete(:icon) || 'upload'

        @template.content_tag(:div, wrapper_options(non_selected_text)) do
          @template.content_tag(:label, class: 'file-label') do
            file_field(method, options) +
              file_cta(file_icon_name, choose_file_text) +
              filename(non_selected_text)
          end
        end
      end

      def file_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end

      private

      def wrapper_options(non_selected_text)
        {
          class: 'field file has-name',
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
        @template.content_tag(:span, class: 'file-cta') do
          file_icon = @template.content_tag(:span, class: 'file-icon') do
            @template.render(Bali::Icon::Component.new(file_icon_name))
          end

          file_label = @template.content_tag(:span, choose_file_text, class: 'file-label')

          file_icon + file_label
        end
      end
    end
  end
end
