# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RecurringEventRuleFields
      def recurring_event_rule_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          recurring_event_rule_field(method, options)
        end
      end

      def recurring_event_rule_field(method, options = {})
        value = options.delete(:value)
        @template.render(
          Bali::RecurringEventRuleForm::Component.new(self, method, value, **options)
        )
      end
    end
  end
end
