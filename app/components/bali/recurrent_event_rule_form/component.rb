# frozen_string_literal: true

module Bali
  module RecurrentEventRuleForm
    # Recurrence Rule Form - Build RRULE strings (RFC 5545) for calendar applications.
    #
    # Generates standard iCalendar recurrence rules for scheduling recurring events.
    # The UI provides intuitive controls for frequency, interval, weekday selection,
    # and end conditions.
    #
    # == RRULE Format
    #
    # The component outputs RFC 5545 compliant strings like:
    # - +FREQ=DAILY;INTERVAL=1+ (every day)
    # - +FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR+ (every 2 weeks on Mon/Wed/Fri)
    # - +FREQ=MONTHLY;BYSETPOS=-1;BYDAY=FR+ (last Friday of each month)
    # - +FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1+ (January 1st yearly)
    #
    # == Usage
    #
    #   # Basic usage with form builder
    #   form.recurrent_event_rule_field :schedule
    #
    #   # With field group wrapper (includes label)
    #   form.recurrent_event_rule_field_group :schedule
    #
    #   # Pre-populated with existing value
    #   form.recurrent_event_rule_field :schedule, value: 'FREQ=WEEKLY;BYDAY=MO'
    #
    #   # Limit available frequencies
    #   form.recurrent_event_rule_field :schedule, frequency_options: %w[daily weekly]
    #
    #   # Hide end date options (for rules that never end)
    #   form.recurrent_event_rule_field :schedule, skip_end_method: true
    #
    # == Options
    #
    # [+form+]              Required. The form builder instance.
    # [+method+]            Required. The attribute name (e.g., +:schedule+).
    # [+value+]             Optional. Pre-populate with an existing RRULE string.
    # [+disabled+]          Optional. Disable all form controls (default: false).
    # [+skip_end_method+]   Optional. Hide the "End" section (default: false).
    # [+frequency_options+] Optional. Array of allowed frequencies (default: all).
    #                       Valid values: yearly, monthly, weekly, daily, hourly.
    #
    class Component < ApplicationViewComponent
      FREQUENCIES = {
        yearly: 0,
        monthly: 1,
        weekly: 2,
        daily: 3,
        hourly: 4
      }.freeze

      DEFAULT_FREQUENCIES = %w[yearly monthly weekly daily hourly].freeze

      BYSETPOS_VALUES = {
        first: 1,
        second: 2,
        third: 3,
        fourth: 4,
        last: -1
      }.freeze

      BASE_CLASSES = 'recurrent-event-rule-form-component'

      private_constant :FREQUENCIES, :DEFAULT_FREQUENCIES, :BYSETPOS_VALUES, :BASE_CLASSES

      # rubocop:disable Metrics/ParameterLists -- Configuration options are explicit and self-documenting
      def initialize(form:, method:, value: nil, disabled: false, skip_end_method: false,
                     frequency_options: nil, **options)
        # rubocop:enable Metrics/ParameterLists
        @form = form
        @method = method
        @value = value
        @disabled = disabled
        @skip_end_method = skip_end_method
        @allowed_frequencies = frequency_options&.map(&:to_s) || DEFAULT_FREQUENCIES
        @options = options
      end

      private

      attr_reader :form, :method, :value, :disabled, :skip_end_method, :allowed_frequencies,
                  :options

      def unique_id
        @unique_id ||= SecureRandom.hex(4)
      end

      def component_classes
        class_names(
          BASE_CLASSES,
          '[&_.weekday-checkboxes-container]:flex',
          '[&_.weekday-checkboxes-container]:flex-wrap',
          '[&_.weekday-checkboxes-container]:justify-center',
          '[&_.weekday-checkboxes-container]:sm:justify-start',
          '[&_.weekday-checkboxes-container]:gap-1.5',
          '[&_.weekday-checkboxes-container]:sm:gap-2',
          options[:class]
        )
      end

      def component_data
        prepend_controller(options, 'recurrent-event-rule').fetch(:data, {})
      end

      def frequency_options
        FREQUENCIES.map do |name, freq_value|
          [t(".#{name}"), freq_value, { disabled: allowed_frequencies.exclude?(name.to_s) }]
        end
      end

      def ending_options
        [
          [t('.never'), ''],
          [t('.after'), 'count'],
          [t('.on_date'), 'until']
        ]
      end

      def bysetpos_options
        BYSETPOS_VALUES.map { |name, pos_value| [t(".#{name}"), pos_value] }
      end

      def byweekday_options
        day_options = I18n.t('date.day_names').map.with_index do |day, index|
          [day, index.zero? ? 6 : index - 1]
        end
        day_options << [t('.day'), '6,0,1,2,3,4,5']
        day_options << [t('.weekday'), '0,1,2,3,4']
        day_options << [t('.weekend_day'), '6,5']
        day_options
      end

      def bymonth_options
        I18n.t('date.month_names').compact.map.with_index do |month, index|
          [month, index + 1]
        end
      end

      def bymonthday_options
        (1..31).map(&:to_s)
      end
    end
  end
end
