# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RadioButtonsGroupFields
      def radio_buttons_group(method, values, options = {}, html_options = {})
        options.with_defaults!(
          toggler: {
            type: :radio,
            data: { action: 'radio-toggle#change' }
          }
        )
        selected = options.delete(:selected) || nil
        radio_name = options.delete(:radio_name) || ''

        @template.safe_join([
          @template.content_tag(:div, data: {
            controller: 'radio-toggle',
            'toggle-radio-current-value': values.first.first
          }) {
            @template.safe_join(buttons(values, nil, radio_name, options))
          }
        ])
      end

      private

      def buttons(values, selected, radio_name, options)
        values.map.with_index do |value, index|
          toggler_class = class_names('button mr-2', 'is-active': selected == value.last || (index == 0 && selected.blank?)) || ''
          @template.safe_join([
            @template.content_tag(:input, '', options[:toggler].with_defaults(
              class: 'is-h idden',
              name: 'radio-toggle-button-' + radio_name,
            )),
            @template.content_tag(:label, value.first, { class: toggler_class, for: 'radio-toggle-button-' + value.first })
          ])
          #@template.content_tag(:li, data: { tab: index, value: value.last }, class: active) do
          #  @template.content_tag(:a, '', options) do
          #    @template.content_tag(:span, value.first)
          #  end
          #end
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
