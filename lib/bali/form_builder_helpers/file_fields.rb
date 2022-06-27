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

        file_cta = @template.content_tag(:span, class: 'file-cta') do
          file_icon = @template.content_tag(:span, class: 'file-icon') do
            @template.render(Bali::Icon::Component.new(file_icon_name))
          end

          file_label = @template.content_tag(:span, choose_file_text, class: 'file-label')
          file_icon + file_label
        end

        filename = @template.content_tag(
          :span, non_selected_text, class: 'file-name', data: { 'file-input-target': 'value' }
        )

        wrapper_options = {
          class: 'field file has-name',
          data: {
            controller: 'file-input',
            'file-input-non-selected-text-value': non_selected_text
          }
        }

        @template.content_tag(:div, wrapper_options) do
          @template.content_tag(:label, class: 'file-label') do
            file_field(method, options) + file_cta + filename
          end
        end
      end

      def file_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end
