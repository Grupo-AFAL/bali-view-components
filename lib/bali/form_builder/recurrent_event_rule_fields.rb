# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RecurrentEventRuleFields
      def recurrent_event_rule_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
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
