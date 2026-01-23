# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SharedDateUtils
      WRAPPER_CLASS = 'fieldset flatpickr'
      BUTTON_CLASS = 'btn btn-ghost'
      JOIN_ITEM_CLASS = 'join-item'
      CLEAR_BUTTON_CLASS = "#{BUTTON_CLASS} #{JOIN_ITEM_CLASS}".freeze
      NAV_BUTTON_CLASS = "#{BUTTON_CLASS} #{JOIN_ITEM_CLASS}".freeze

      def date_field(method, options = {})
        opts = options.dup
        clear_btn = build_clear_button if opts.delete(:clear)
        opts[:control_class] = ['w-full', opts[:control_class]].compact.join(' ')

        wrapper_options = build_wrapper_options(method, opts)

        content_tag(:div, wrapper_options) do
          build_date_input(clear_btn, method, opts)
        end
      end

      def controller_values(method, options)
        values = {
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
          values[:default_dates] = [options[:value].first, options[:value].last]
        end

        values
      end

      private

      def build_clear_button
        aria_label = I18n.t('bali.form_builder.date_fields.clear', default: 'Clear date')

        content_tag(:div, class: JOIN_ITEM_CLASS) do
          content_tag(:button, class: CLEAR_BUTTON_CLASS, type: 'button',
                               data: { action: 'datepicker#clear' },
                               'aria-label': aria_label) do
            @template.render(Bali::Icon::Component.new('times-circle'))
          end
        end
      end

      def build_wrapper_options(method, options)
        wrapper_class = class_names(WRAPPER_CLASS, 'join' => options[:manual])

        wrapper_options = {
          class: wrapper_class,
          data: {
            controller: 'datepicker',
            'datepicker-period-value': options[:period],
            'datepicker-locale-value': I18n.locale
          }
        }.merge!(options.delete(:wrapper_options) || {})

        prepend_values(wrapper_options, 'datepicker', controller_values(method, options))
        wrapper_options
      end

      def build_date_input(clear_btn, method, options)
        if options[:manual]
          input = text_field(method, options)
          safe_join([previous_date_button, input, next_date_button, clear_btn].compact)
        else
          safe_join([text_field(method, options), clear_btn].compact)
        end
      end

      def alt_input_class(method, options)
        base_class = options[:alt_input_class] || 'input input-bordered w-full'
        return "#{base_class} input-error" if errors?(method)

        base_class
      end

      def previous_date_button
        aria_label = I18n.t('bali.form_builder.date_fields.previous', default: 'Previous date')

        content_tag(:button, @template.render(Bali::Icon::Component.new('arrow-back')),
                    class: NAV_BUTTON_CLASS,
                    type: 'button',
                    data: { action: 'datepicker#previousDate' },
                    'aria-label': aria_label)
      end

      def next_date_button
        aria_label = I18n.t('bali.form_builder.date_fields.next', default: 'Next date')

        content_tag(:button, @template.render(Bali::Icon::Component.new('arrow-forward')),
                    class: NAV_BUTTON_CLASS,
                    type: 'button',
                    data: { action: 'datepicker#nextDate' },
                    'aria-label': aria_label)
      end
    end
  end
end
