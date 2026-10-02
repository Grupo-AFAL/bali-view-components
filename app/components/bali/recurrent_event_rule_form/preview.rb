# frozen_string_literal: true

module Bali
  module RecurrentEventRuleForm
    # @label RecurrentEventRuleForm
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Renders a recurrence rule form with all options enabled.
      # The form generates RRULE strings (RFC 5545) for calendar applications.
      def default
        render_with_template(locals: { model: form_record })
      end

      # @label With Existing Value
      # Pre-populates the form with an existing RRULE value.
      # The component parses and displays the rule correctly.
      # @param value text
      def with_value(value: "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=10")
        render_with_template(locals: { model: form_record, value: value })
      end

      # @label Monthly Pattern
      # Shows a monthly recurrence pattern.
      def monthly_pattern
        render_with_template(locals: {
          model: form_record,
          value: "FREQ=MONTHLY;INTERVAL=1;BYSETPOS=-1;BYDAY=FR"
        })
      end

      # @label Limited Frequencies
      # Only allows weekly and daily frequencies.
      # Useful when you want to restrict user choices.
      def limited_frequencies
        render_with_template(locals: {
          model: form_record,
          frequency_options: %w[weekly daily]
        })
      end

      # @label Without End Date
      # Hides the "End" section for rules that never end.
      def without_end
        render_with_template(locals: {
          model: form_record,
          skip_end_method: true
        })
      end

      # @label Disabled State
      # Shows the form in a read-only/disabled state.
      # @param value text
      def disabled(value: "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE")
        render_with_template(locals: { model: form_record, value: value, disabled: true })
      end
    end
  end
end
