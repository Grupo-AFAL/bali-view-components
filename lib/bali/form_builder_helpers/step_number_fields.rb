module Bali
  module FormBuilderHelpers
    module StepNumberFields
      def step_number_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          step_number_field(method, options)
        end
      end

      def step_number_field(method, options = {})
        options[:data] ||= {}
        options[:data]['step-number-input-target'] = 'input'
  
        subtract_data = options.delete(:subtract_data) || {}
        add_data = options.delete(:add_data) || {}
  
        subtract_button_data = {
          action: ['step-number-input#subtract', subtract_data[:action]].compact.join(' '),
          'step-number-input-target': 'subtract'
        }
  
        add_button_data = {
          action: ['step-number-input#add', add_data[:action]].compact.join(' '),
          'step-number-input-target': 'add'
        }
  
        disabled = options[:disabled]
        button_class = class_names(['button', options[:button_class]], 'is-static': disabled)
  
        @template.content_tag(:div, class: 'field has-addons',
                                    data: { controller: 'step-number-input' }) do
          addon_left = @template.content_tag(:div, class: 'control') do
            @template.link_to Bali::Icon::Component.new('minus').call, 
                              '', class: button_class, disabled: disabled,
                              data: disabled ? {} : subtract_button_data,
                              title: 'subtract'
          end
  
          input = @template.content_tag(:div, class: 'control') do
            number_field(method, options)
          end
  
          addon_right = @template.content_tag(:div, class: 'control') do
            @template.link_to Bali::Icon::Component.new('plus').call, 
                              '', class: button_class, disabled: disabled,
                              data: disabled ? {} : add_button_data,
                              title: 'add'
          end
  
          @template.safe_join([addon_left, input, addon_right])
        end
      end  
    end
  end
end