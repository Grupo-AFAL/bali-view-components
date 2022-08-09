# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RadioFields
      def radio_field_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          radio_field(method, values, options, html_options)
        end
      end

      def radio_field(method, values, options = {}, html_options = {})
        label_class = class_names(['radio', html_options.delete(:radio_label_class)])

        field = @template.safe_join(tags(values, html_options, method, label_class))
        field_helper(method, field, options)
      end

      def radio_buttons_group(
        method, values, options = {}, togglers_options = {}, radios_options = {}
      )
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          radio_buttons_field(
            method, values, options, togglers_options, radios_options
          )
        end
      end

      def radio_buttons_field(
        method, values, options = {}, togglers_options = {}, radios_options = {}
      )
        current_value = options.delete(:current_value) ||
                        values.find { |key, _| values[key].present? }&.first

        options[:control_class] = "radio-buttons-group #{options[:control_class] || ''}"
        options[:control_data] ||= {}
        options[:control_data].merge!(
          controller: 'radio-buttons-group',
          'radio-buttons-group-current-value': current_value,
          'radio-buttons-group-keep-selection-value': options.delete(:keep_selection)
        )

        field = safe_join([
                            togglers(values, togglers_options),
                            radio_buttons(method, values, radios_options)
                          ])

        field_helper(method, field, options)
      end

      private

      def togglers(values, options)
        options = prepend_class_name(options, 'togglers')
        toggler_opts = toggler_options(options)

        tag.div(**options) do
          safe_join(values.keys.map do |value|
            toggler_opts[:disabled] = values[value].blank?
            toggler_opts[:value] = value

            tag.button(value, **toggler_opts)
          end)
        end
      end

      def toggler_options(options)
        opts = options.delete(:toggler) || {}
        opts = prepend_class_name(opts, 'toggler')
        opts = prepend_action(opts, 'radio-buttons-group#change')
        opts = prepend_data_attribute(opts, 'radio-buttons-group-target', 'toggler')
        opts[:type] = 'button'

        opts
      end

      def radio_buttons(method, values, options)
        options = prepend_data_attribute(options, 'radio-buttons-group-target', 'element')

        label_options = options.delete(:label) || {}
        label_options = prepend_class_name(label_options, 'radio')

        safe_join(values.map do |category, category_values|
          options[:data]['radio-buttons-group-value'] = category

          tag.div(**options) do
            safe_join(
              tags(
                category_values,
                { data: { action: 'click->radio-buttons-group#select' } },
                method, label_options[:class]
              )
            )
          end
        end)
      end

      def tags(values, html_options, method, label_class)
        field_name = [object.model_name.singular, method].join('_')
        data = html_options.delete(:data)

        values.map do |display_value|
          display, value, radio_options = display_value
          radio_options ||= {}
          radio_options.merge!(html_options)

          label(method, class: label_class, for: [field_name, value].join('_')) do
            radio_button(method, value, radio_options.merge(data: data)) + display
          end
        end
      end
    end
  end
end
