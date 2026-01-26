# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::TimePeriods::SelectOptions do
  describe '.yearly_quarter' do
    subject(:options) { described_class.yearly_quarter }

    it 'returns 5 options (yearly + 4 quarters)' do
      expect(options.length).to eq 5
    end

    it 'includes yearly option with i18n' do
      expect(options.first.first).to eq I18n.t('bali.time_periods.yearly')
    end

    it 'includes Q1-Q4 options' do
      labels = options.map(&:first)
      expect(labels).to include('Q1', 'Q2', 'Q3', 'Q4')
    end

    it 'returns date ranges as values' do
      # options is an array of [label, range] pairs, not a hash
      options.each do |_label, range| # rubocop:disable Style/HashEachMethods
        expect(range).to be_a(Range)
      end
    end
  end

  describe '.months' do
    subject(:options) { described_class.months }

    it 'returns 12 options (one per month)' do
      expect(options.length).to eq 12
    end

    it 'uses localized month names' do
      month_names = I18n.t('date.month_names').compact
      option_labels = options.map(&:first)
      expect(option_labels).to eq month_names
    end
  end

  describe '.trailing' do
    subject(:options) { described_class.trailing }

    it 'returns 5 trailing period options' do
      expect(options.length).to eq 5
    end

    it 'includes common trailing periods' do
      labels = options.map(&:first)
      expect(labels).to include(
        I18n.t('bali.time_periods.yesterday'),
        I18n.t('bali.time_periods.last_7_days'),
        I18n.t('bali.time_periods.last_30_days')
      )
    end
  end
end
