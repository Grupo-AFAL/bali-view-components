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
        value = options.delete(:value)
        @template.render(
          Bali::RecurrentEventRuleForm::Component.new(self, method, value, **options)
        )
      end
    end
  end
end
