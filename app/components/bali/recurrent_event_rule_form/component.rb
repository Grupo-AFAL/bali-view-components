# frozen_string_literal: true

module Bali
  module RecurrentEventRuleForm
    class Component < ApplicationViewComponent
      def initialize(form, method, value, **options)
        @form = form
        @method = method
        @value = value
        @disabled = options.delete(:disabled) || false
        @skip_end_method = options.delete(:skip_end_method) || false
        @frequency_options = options.delete(:frequency_options)&.map(&:to_s) ||
                             %w[yearly monthly weekly daily hourly]
        @options = prepend_class_name(options,
                                      'recurrent-event-rule-form-component [&_.weekday-checkboxes-container]:flex [&_.weekday-checkboxes-container]:gap-4 [&_.weekday-checkboxes-container]:w-full [&_.weekday-checkboxes-container]:overflow-x-scroll')
        @options = prepend_controller(options, 'recurrent-event-rule')
      end

      private

      def timestamp
        @timestamp ||= Time.zone.now.to_f.to_s.gsub('.', '_')
      end

      def frequency_options
        [
          [translate('yearly'), 0, { disabled: @frequency_options.exclude?('yearly') }],
          [translate('monthly'), 1, { disabled: @frequency_options.exclude?('monthly') }],
          [translate('weekly'), 2, { disabled: @frequency_options.exclude?('weekly') }],
          [translate('daily'), 3, { disabled: @frequency_options.exclude?('daily') }],
          [translate('hourly'), 4, { disabled: @frequency_options.exclude?('hourly') }]
        ]
      end

      def ending_options
        [
          [translate('never'), ''],
          [translate('after'), 'count'],
          [translate('on_date'), 'until']
        ]
      end

      def bysetpos_options
        [
          [translate('first'), 1],
          [translate('second'), 2],
          [translate('fourth'), 4],
          [translate('third'), 3],
          [translate('last'), -1]
        ]
      end

      def byweekday_options
        options = I18n.t('date.day_names').map.with_index do |day, index|
          [day, index.zero? ? 6 : index - 1]
        end
        options << [translate('day'), '6,0,1,2,3,4,5']
        options << [translate('weekday'), '0,1,2,3,4']
        options << [translate('weekend_day'), '6,5']
        options
      end

      def bymonth_options
        I18n.t('date.month_names').compact.map.with_index do |month, index|
          [month, index + 1]
        end
      end

      def translate(key)
        I18n.t("view_components.bali.recurrent_event_rule_form.#{key}")
      end
    end
  end
end
