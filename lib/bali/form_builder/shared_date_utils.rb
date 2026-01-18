# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SharedDateUtils
      def date_field(method, options = {})
        clear_btn = if options.delete(:clear)
                      content_tag(:div, class: 'join-item') do
                        content_tag(:button, class: 'btn btn-ghost', type: 'button',
                                             data: { action: 'datepicker#clear' }) do
                          @template.render(Bali::Icon::Component.new('times-circle'))
                        end
                      end
                    end

        options[:control_class] = "w-full #{options[:control_class]}"

        wrapper_options = {
          class: 'fieldset flatpickr',
          data: {
            controller: 'datepicker', 'datepicker-period-value': options[:period],
            'datepicker-locale-value': I18n.locale
          }
        }.merge!(options.delete(:wrapper_options) || {})

        wrapper_options[:class] += ' join' if options[:manual]

        prepend_values(wrapper_options, 'datepicker', controller_values(method, options))

        content_tag(:div, wrapper_options) do
          input_date_field(clear_btn, method, options)
        end
      end

      def controller_values(method, options)
        controller_values = {
          disable_weekends: options[:disable_weekends],
          min_date: options[:min_date],
          max_date: options[:max_date],
          alt_input_class: alt_input_class(method, options),
          mode: options[:mode],
          alt_input: options[:alt_input],
          allow_input: options[:allow_input],
          alt_format: options[:alt_format],
          disabled_dates: (options[:disabled_dates] || []).to_json
        }

        if options[:mode] == 'range' && options[:value].respond_to?(:first)
          controller_values[:default_dates] = [options[:value].first, options[:value].last]
        end

        controller_values
      end

      def alt_input_class(method, options)
        return "#{options[:alt_input_class]} input-error" if errors?(method)

        options[:alt_input_class]
      end

      def input_date_field(clear_btn, method, options)
        if options[:manual]
          date_field_previous_btn + text_field(method, options) + date_field_next_btn + clear_btn
        else
          text_field(method, options) + clear_btn
        end
      end

      def date_field_previous_btn
        content_tag(:button, @template.render(Bali::Icon::Component.new('arrow-back')),
                    {
                      class: 'btn btn-ghost join-item',
                      type: 'button',
                      data: { action: 'datepicker#previousDate' }
                    })
      end

      def date_field_next_btn
        content_tag(:button, @template.render(Bali::Icon::Component.new('arrow-forward')),
                    {
                      class: 'btn btn-ghost join-item',
                      type: 'button',
                      data: { action: 'datepicker#nextDate' }
                    })
      end
    end
  end
end
