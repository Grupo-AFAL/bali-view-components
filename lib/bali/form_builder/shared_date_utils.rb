# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SharedDateUtils
      def date_field(method, options = {})
        clear_btn = if options.delete(:clear)
                      content_tag(:div, class: 'control') do
                        content_tag(:a, class: 'button', data: { action: 'datepicker#clear' }) do
                          @template.render(Bali::Icon::Component.new('times-circle'))
                        end
                      end
                    end

        options[:control_class] = "is-fullwidth #{options[:control_class]}"

        wrapper_options = {
          class: 'field flatpickr',
          data: {
            controller: 'datepicker', 'datepicker-period-value': options[:period],
            'datepicker-locale-value': I18n.locale
          }
        }.merge!(options.delete(:wrapper_options) || {})

        wrapper_options[:class] += ' has-addons' if options[:manual]

        if options[:min_date].present?
          wrapper_options.merge!('data-datepicker-min-date-value': options[:min_date])
        end

        content_tag(:div, wrapper_options) do
          input_date_field(clear_btn, method, options)
        end
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
                      class: 'button is-transparent',
                      data: { action: 'datepicker#previousDate' }
                    })
      end

      def date_field_next_btn
        content_tag(:button, @template.render(Bali::Icon::Component.new('arrow-forward')),
                    {
                      class: 'button is-transparent',
                      data: { action: 'datepicker#nextDate' }
                    })
      end
    end
  end
end
