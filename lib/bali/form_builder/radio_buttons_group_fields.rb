# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RadioButtonsGroupFields
      def radio_buttons_group(method, values, options = {}, html_options = {})
        options.with_defaults!(
          data: {},
          class: ''
        )
        selected = options.delete(:selected) || nil
        rounded = options.delete(:rounded) || false
        classes = class_names('tabs is-toggle tabs-fb', 'is-toggle-rounded': rounded)

        @template.safe_join([
          @template.content_tag(:div, data: {
            controller: 'toggle-radio',
            'toggle-radio-current-value': selected
          }) {[
            @template.content_tag(:div, class: classes) {
              @template.content_tag(:ul) do
                @template.safe_join(buttons(values, nil, options))
              end
            },

            @template.content_tag(:div, class: 'tab-content tabs-fb') {
              options[:div_class] = classes
              @template.safe_join(contents(values, selected, options))
            }
          ]}
        ])
      end

      private

      def buttons(values, selected, options)
        values.map.with_index do |value, index|
          active = class_names('is-active': selected == value.last || (index == 0 && selected.blank?)) || ''
          @template.content_tag(:li, data: { tab: index, value: value.last }, class: active) do
            @template.content_tag(:a, '', options) do
              @template.content_tag(:span, value.first)
            end
          end
        end
      end

      def contents(values, selected, options)
        classes = options.delete(:div_class) || ''
        values.map.with_index do |value, index|
          @template.content_tag(:div, data: { content: index }, class: class_names('is-active': index == 0)) do
            @template.content_tag(:div, class: classes) do
              @template.content_tag(:ul) do
                @template.safe_join(buttons(value.last, selected, options))
              end
            end
          end
        end
      end
    end
  end
end
