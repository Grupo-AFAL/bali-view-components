# frozen_string_literal: true

require 'rails_helper'

class ActiveModelWithDateRangeAttribute
  include ActiveModel::Attributes
  include Bali::Concerns::DateRangeAttribute

  date_range_attribute :date_range
end

Workout.class_eval do
  include Bali::Concerns::DateRangeAttribute

  attribute :starts_at
  attribute :ends_at

  date_range_attribute :date_range, start_attribute: :starts_at, end_attribute: :ends_at
end

RSpec.describe Bali::Concerns::DateRangeAttribute do
  context 'without start_attribute and end_attribute' do
    let(:model) { ActiveModelWithDateRangeAttribute.new }
  
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

  context 'with start_attribute and end_attribute' do
    let(:model) { Workout.new }
  
    describe '#date_range' do
      before { model.date_range = Time.zone.now.all_day }
  
      it { expect(model.date_range).to eq(Time.zone.now.all_day) }
      it { expect(model.starts_at).to eq(Time.zone.now.beginning_of_day) }
      it { expect(model.ends_at).to eq(Time.zone.now.end_of_day) }
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
        it { expect(model.starts_at).to eq(Time.zone.local(2023, 3, 1)) }
        it { expect(model.ends_at).to eq(Time.zone.local(2023, 3, 10).end_of_day) }
      end
  
      context 'with a day as a range' do
        let(:range) { Time.zone.local(2023, 3, 1)..Time.zone.local(2023, 3, 1).end_of_day }
  
        before { model.date_range = '2023-03-01' }
  
        it { expect(model.date_range).to eq(range) }
        it { expect(model.starts_at).to eq(Time.zone.local(2023, 3, 1)) }
        it { expect(model.ends_at).to eq(Time.zone.local(2023, 3, 1).end_of_day) }
      end
  
      context 'with date range missing' do
        before { model.date_range = '' }
  
        it { expect(model.date_range).to be_nil }
        it { expect(model.starts_at).to be_nil }
        it { expect(model.ends_at).to be_nil }
      end

      context 'when assigning start_attribute and end_attribute' do
        before do
          model.starts_at = Time.zone.now.beginning_of_day
          model.ends_at = 1.week.from_now.end_of_day
        end

        it { expect(model.date_range).to eq(Time.zone.now.beginning_of_day..1.week.from_now.end_of_day) }
      end
    end
  end
end
