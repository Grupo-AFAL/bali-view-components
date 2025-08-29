# frozen_string_literal: true

module Bali
  module RecurringEventRuleForm
    class Component < ApplicationViewComponent
      def initialize(form, method, value, **options)
        @form = form
        @method = method
        @value = value
        @options = prepend_class_name(options, 'recurring-event-rule-form-component')
        @options = prepend_controller(options, 'recurring-event-rule')
      end

      private

      def timestamp
        @timestamp ||= Time.zone.now.to_f.to_s.gsub('.', '_')
      end

      def frequency_options
        [
          [translate('yearly'), 0],
          [translate('monthly'), 1],
          [translate('weekly'), 2],
          [translate('daily'), 3],
          [translate('hourly'), 4]
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
        translate('date.month_names').compact.map.with_index do |month, index|
          [month, index + 1]
        end
      end

      def translation(key)
        I18n.t("view_components.bali.recurring_event_rule_form.#{key}")
      end
    end
  end
end
