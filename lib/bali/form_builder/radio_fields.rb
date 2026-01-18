# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RadioFields # rubocop:disable Metrics/ModuleLength
      RADIO_CLASS = 'radio'
      LABEL_CLASS = 'label cursor-pointer'
      LABEL_TEXT_CLASS = 'label-text'
      ERROR_CLASS = 'label-text-alt text-error'
      TOGGLERS_CLASS = 'togglers'
      TOGGLER_CLASS = 'toggler'
      TOGGLER_TYPE = 'button'
      RADIO_BUTTONS_GROUP_CLASS = 'radio-buttons-group'

      SIZES = {
        xs: 'radio-xs',
        sm: 'radio-sm',
        md: 'radio-md',
        lg: 'radio-lg'
      }.freeze

      COLORS = {
        primary: 'radio-primary',
        secondary: 'radio-secondary',
        accent: 'radio-accent',
        success: 'radio-success',
        warning: 'radio-warning',
        info: 'radio-info',
        error: 'radio-error'
      }.freeze

      CONTROLLER_NAME = 'radio-buttons-group'

      def radio_field_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          radio_field(method, values, options, html_options)
        end
      end

      def radio_field(method, values, options = {}, html_options = {})
        label_class = build_radio_label_class(html_options)
        radio_opts = build_radio_input_options(method, html_options)

        field = safe_join(render_radio_buttons(
                            values,
                            method: method,
                            label_class: label_class,
                            radio_options: radio_opts
                          ))
        field_helper(method, field, options)
      end

      def radio_buttons_group(method, values, options = {}, togglers_options = {},
                              radios_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          radio_buttons_field(method, values, options, togglers_options, radios_options)
        end
      end

      def radio_buttons_field(method, values, options = {}, togglers_options = {},
                              radios_options = {})
        current_value = extract_current_value(values, options)
        control_options = build_control_options(options, current_value)

        field = safe_join(
          [render_togglers(values, togglers_options),
           render_grouped_radios(method, values, radios_options)]
        )

        field_helper(method, field, control_options)
      end

      private

      def build_radio_label_class(html_options)
        custom_class = html_options[:radio_label_class]
        [LABEL_CLASS, custom_class].compact.join(' ')
      end

      def build_radio_input_options(method, html_options)
        size = html_options[:size]
        color = html_options[:color]
        custom_class = html_options[:class]

        radio_class = [
          RADIO_CLASS,
          SIZES[size],
          COLORS[color],
          (errors?(method) ? 'radio-error' : nil),
          custom_class
        ].compact.join(' ')

        html_options.except(:radio_label_class, :size, :color, :class, :data)
                    .merge(class: radio_class)
      end

      def extract_current_value(values, options)
        options[:current_value] || values.find { |key, _| values[key].present? }&.first
      end

      def build_control_options(options, current_value)
        keep_selection = options[:keep_selection]

        control_class = [RADIO_BUTTONS_GROUP_CLASS, options[:control_class]].compact.join(' ')
        control_data = (options[:control_data] || {}).merge(
          controller: CONTROLLER_NAME,
          "#{CONTROLLER_NAME}-current-value": current_value,
          "#{CONTROLLER_NAME}-keep-selection-value": keep_selection
        )

        options.except(:current_value, :keep_selection)
               .merge(control_class: control_class, control_data: control_data)
      end

      def render_radio_buttons(values, method:, label_class:, radio_options:)
        data = radio_options[:data]

        values.map do |display_value|
          display, value, item_options = display_value
          merged_options = radio_options.merge(item_options || {}).merge(data: data)

          label(method, class: label_class, value: value) do
            safe_join(
              [radio_button(method, value, merged_options),
               content_tag(:span, display, class: LABEL_TEXT_CLASS)]
            )
          end
        end
      end

      def render_togglers(values, options)
        container_options = options.except(:toggler)
        container_options[:class] = [TOGGLERS_CLASS, container_options[:class]].compact.join(' ')
        toggler_opts = build_toggler_options(options)

        content_tag(:div, **container_options) do
          safe_join(values.keys.map do |value|
            item_opts = toggler_opts.merge(
              disabled: values[value].blank?,
              value: value
            )
            content_tag(:button, value, **item_opts)
          end)
        end
      end

      def build_toggler_options(options)
        opts = (options[:toggler] || {}).dup
        opts[:class] = [TOGGLER_CLASS, opts[:class]].compact.join(' ')
        opts = prepend_action(opts, "#{CONTROLLER_NAME}#change")
        opts = prepend_data_attribute(opts, "#{CONTROLLER_NAME}-target", 'toggler')
        opts[:type] = TOGGLER_TYPE
        opts
      end

      def render_grouped_radios(method, values, options)
        container_options = prepend_data_attribute(
          options.except(:label),
          "#{CONTROLLER_NAME}-target",
          'element'
        )

        label_class = [LABEL_CLASS, options.dig(:label, :class)].compact.join(' ')

        safe_join(values.map do |category, category_values|
          item_options = container_options.dup
          item_options[:data] = (item_options[:data] || {}).merge(
            "#{CONTROLLER_NAME}-value" => category
          )

          content_tag(:div, **item_options) do
            safe_join(render_radio_buttons(
                        category_values,
                        method: method,
                        label_class: label_class,
                        radio_options: { data: { action: "click->#{CONTROLLER_NAME}#select" } }
                      ))
          end
        end)
      end
    end
  end
end
