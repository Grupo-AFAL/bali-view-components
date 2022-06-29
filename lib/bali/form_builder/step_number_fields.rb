# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module StepNumberFields
      def step_number_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          step_number_field(method, options)
        end
      end

      def step_number_field(method, options = {})
        options[:data] ||= {}
        options[:data]['step-number-input-target'] = 'input'

        @template.content_tag(:div, class: 'field has-addons',
                                    data: { controller: 'step-number-input' }) do
          @template.safe_join([
                                addon_left(options),
                                step_number_input(method, options),
                                addon_right(options)
                              ])
        end
      end

      private

      def subtract_button_data(options)
        return @subtract_button_data if defined? @subtract_button_data

        subtract_data = options.delete(:subtract_data) || {}
        @subtract_button_data ||= {
          action: ['step-number-input#subtract', subtract_data[:action]].compact.join(' '),
          'step-number-input-target': 'subtract'
        }
      end

      def add_button_data(options)
        return @add_button_data if defined? @add_button_data

        add_data = options.delete(:add_data) || {}
        @add_button_data ||= {
          action: ['step-number-input#add', add_data[:action]].compact.join(' '),
          'step-number-input-target': 'add'
        }
      end

      def addon_button_class(options)
        @addon_button_class ||= class_names(
          ['button', options[:button_class]], 'is-static': options[:disabled]
        )
      end

      def addon_left(options)
        @template.content_tag(:div, class: 'control') do
          @template.link_to @template.render(Bali::Icon::Component.new('minus')),
                            '', class: addon_button_class(options), disabled: options[:disabled],
                                data: options[:disabled] ? {} : subtract_button_data(options),
                                title: 'subtract'
        end
      end

      def step_number_input(method, options)
        @template.content_tag(:div, class: 'control') do
          number_field(method, options)
        end
      end

      def addon_right(options)
        @template.content_tag(:div, class: 'control') do
          @template.link_to @template.render(Bali::Icon::Component.new('plus')),
                            '', class: addon_button_class(options), disabled: options[:disabled],
                                data: options[:disabled] ? {} : add_button_data(options),
                                title: 'add'
        end
      end
    end
  end
end
