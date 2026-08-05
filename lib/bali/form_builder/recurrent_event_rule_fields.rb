# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RecurrentEventRuleFields
      # The caption stays a `<legend>`: the component is a composite of a dozen
      # selects and radios, each named on its own, over a hidden field.
      def recurrent_event_rule_group(method, **options)
        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false)
        ) do
          recurrent_event_rule_field(method, options)
        end
      end

      def recurrent_event_rule_field(method, options = {})
        value = options[:value] || object.try(method)

        @template.render(
          Bali::RecurrentEventRuleForm::Component.new(
            form: self,
            method: method,
            value: value,
            # The component prepends its Stimulus controller into `:data` in
            # place, so it gets a copy rather than the caller's nested hash.
            **dup_options(options).except(:value)
          )
        )
      end
    end
  end
end
