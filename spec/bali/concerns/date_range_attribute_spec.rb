# frozen_string_literal: true

require 'rails_helper'

class ModelWithDateRangeAttribute
  include ActiveModel::Attributes
  include Bali::Concerns::DateRangeAttribute

  date_range_attribute :date_range
end

RSpec.describe Bali::Concerns::DateRangeAttribute do
  let(:model) { ModelWithDateRangeAttribute.new }

  describe '#date_range' do
    before { model.date_range = Time.zone.now.all_day }

    it { expect(model.date_range).to eq(Time.zone.now.all_day) }
  end

  describe '#date_range=' do
    context 'with range' do
      before { model.date_range = Time.zone.now.all_day }

      it { expect(model.date_range).to eq(Time.zone.now.all_day) }
    end

    context 'with a valid date range format' do
      let(:range) { Time.zone.local(2023, 3, 1)..Time.zone.local(2023, 3, 10).end_of_day }

      before { model.date_range = '2023-03-01 to 2023-03-10' }

      it { expect(model.date_range).to eq(range) }
    end

    context 'with a day as a range' do
      let(:range) { Time.zone.local(2023, 3, 1)..Time.zone.local(2023, 3, 1).end_of_day }

      before { model.date_range = '2023-03-01' }

      it { expect(model.date_range).to eq(range) }
    end

    context 'with date range missing' do
      before { model.date_range = '' }

      it { expect(model.date_range).to be_nil }
    end
  end
end
