# frozen_string_literal: true

module Bali
  module RecurrentEventRuleForm
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
          '[&_.weekday-checkboxes-container]:gap-2',
          '[&_.weekday-checkboxes-container]:sm:gap-3',
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
