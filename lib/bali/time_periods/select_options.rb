# frozen_string_literal: true

module Bali
  module TimePeriods
    class SelectOptions
      class << self
        def yearly_quarter
          beginning_of_period = Time.zone.now.beginning_of_year
          [
            [I18n.t('bali.date_ranges.yearly'), Time.zone.now.all_year],
            ['Q1', beginning_of_period..(beginning_of_period + 2.months).end_of_month],
            ['Q2', (beginning_of_period + 3.months)..(beginning_of_period + 5.months).end_of_month],
            ['Q3', (beginning_of_period + 6.months)..(beginning_of_period + 8.months).end_of_month],
            ['Q4', (beginning_of_period + 9.months)..beginning_of_period.end_of_year]
          ]
        end

        def months
          beginning_of_period = Time.zone.now.beginning_of_year
          I18n.t('date.month_names').compact.map.with_index do |month, index|
            [month, (beginning_of_period + index.months).all_month]
          end
        end

        # rubocop: disable Metrics/AbcSize
        def trailing
          [
            [I18n.t('bali.date_ranges.yesterday'), Time.zone.now.yesterday.all_day],
            [I18n.t('bali.date_ranges.last_7_days'),
             7.days.ago.beginning_of_day..Time.zone.now.yesterday.end_of_day],
            [I18n.t('bali.date_ranges.last_30_days'),
             30.days.ago.beginning_of_day..Time.zone.now.yesterday.end_of_day],
            [I18n.t('bali.date_ranges.last_12_weeks'),
             11.weeks.ago.beginning_of_week..Time.zone.now.end_of_week],
            [I18n.t('bali.date_ranges.last_12_months'),
             11.months.ago.beginning_of_month..Time.zone.now.end_of_month]
          ]
        end
        # rubocop: enable Metrics/AbcSize
      end
    end
  end
end
