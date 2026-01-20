# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module StepNumberFields
      BUTTON_BASE_CLASSES = 'btn join-item'
      BUTTON_DISABLED_CLASSES = 'btn-disabled pointer-events-none'
      INPUT_CLASSES = 'input input-bordered join-item text-center'

      def step_number_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          step_number_field(method, options)
        end
      end

      def step_number_field(method, options = {})
        button_opts = extract_button_options(options)
        input_options = build_step_number_input_options(options)

        @template.content_tag(:div, class: 'join', data: { controller: 'step-number-input' }) do
          @template.safe_join([
                                subtract_button(button_opts),
                                number_field(method, input_options),
                                add_button(button_opts)
                              ])
        end
      end

      private

      def extract_button_options(options)
        {
          subtract_data: options.delete(:subtract_data) || {},
          add_data: options.delete(:add_data) || {},
          button_class: options.delete(:button_class),
          disabled: options[:disabled]
        }
      end

      def build_step_number_input_options(options)
        opts = options.dup
        opts[:data] ||= {}
        opts[:data]['step-number-input-target'] = 'input'
        opts[:class] = @template.class_names(INPUT_CLASSES, opts[:class])
        opts
      end

      def subtract_button(opts)
        step_button(
          icon: 'minus',
          action: 'subtract',
          target: 'subtract',
          label: subtract_label,
          extra_data: opts[:subtract_data],
          button_class: opts[:button_class],
          disabled: opts[:disabled]
        )
      end

      def add_button(opts)
        step_button(
          icon: 'plus',
          action: 'add',
          target: 'add',
          label: add_label,
          extra_data: opts[:add_data],
          button_class: opts[:button_class],
          disabled: opts[:disabled]
        )
      end

      def subtract_label
        I18n.t('view_components.bali.step_number_field.decrease', default: 'Decrease value')
      end

      def add_label
        I18n.t('view_components.bali.step_number_field.increase', default: 'Increase value')
      end

      def step_button(opts)
        classes = @template.class_names(
          BUTTON_BASE_CLASSES,
          opts[:button_class],
          BUTTON_DISABLED_CLASSES => opts[:disabled]
        )

        data = build_button_data(opts[:action], opts[:target], opts[:extra_data], opts[:disabled])

        @template.button_tag(
          @template.render(Bali::Icon::Component.new(opts[:icon])),
          type: 'button',
          class: classes,
          disabled: opts[:disabled],
          data: data,
          'aria-label': opts[:label],
          title: opts[:label]
        )
      end

      def build_button_data(action, target, extra_data, disabled)
        return {} if disabled

        action_value = [
          "step-number-input##{action}",
          extra_data[:action]
        ].compact.join(' ')

        extra_data.merge(
          'step-number-input-target' => target,
          action: action_value
        )
      end
    end
  end
end
