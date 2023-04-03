# frozen_string_literal: true

require 'rails_helper'

class ModelWithDateRangeAttribute
  include ActiveModel::Attributes
  include Bali::Concerns::DateRangeAttribute

  date_range_attribute :date_range
end

Workout.class_eval do
  include Bali::Concerns::DateRangeAttribute
  
  date_range_attribute :working_period, start_attribute: :workout_start_at, 
                                        end_attribute: :workout_end_at
  date_range_attribute :available_period, start_attribute: :available_from, 
                                          end_attribute: :available_to
end

RSpec.describe Bali::Concerns::DateRangeAttribute do
  context 'with a class including an ActiveModel::Attributes' do
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

      context 'with an empty date range' do
        before { model.date_range = '' }

        it { expect(model.date_range).to be_nil }
      end
    end
  end

  context 'with a class that inherits from ActiveRecord' do
    let(:model) { Workout.new }

    context 'when start_attribute and end_attributes are DB columns' do
      describe '#working_period' do
        before { model.working_period = Time.zone.now.all_day }
  
        it { expect(model.working_period).to eq(Time.zone.now.all_day) }
        it { expect(model.workout_start_at).to eq(Time.zone.now.beginning_of_day) }
        it { expect(model.workout_end_at).to eq(Time.zone.now.end_of_day) }
      end
  
      describe '#working_period=' do
        context 'with range' do
          before { model.working_period = Time.zone.now.all_day }
  
          it { expect(model.working_period).to eq(Time.zone.now.all_day) }
          it { expect(model.workout_start_at).to eq(Time.zone.now.beginning_of_day) }
          it { expect(model.workout_end_at).to eq(Time.zone.now.end_of_day) }
        end
  
        context 'with a valid date range format' do
          let(:range_start) { Time.zone.local(2023, 3, 1) }
          let(:range_end) { Time.zone.local(2023, 3, 10).end_of_day }
  
          before { model.working_period = '2023-03-01 to 2023-03-10' }
  
          it { expect(model.working_period).to eq(range_start..range_end) }
          it { expect(model.workout_start_at).to eq(range_start) }
          it { expect(model.workout_end_at).to eq(range_end) }
        end
  
        context 'with a day as a range' do
          let(:range_start) { Time.zone.local(2023, 3, 1) }
          let(:range_end) { Time.zone.local(2023, 3, 1).end_of_day }
  
          before { model.working_period = '2023-03-01' }

          it { expect(model.working_period).to eq(range_start..range_end) }
          it { expect(model.workout_start_at).to eq(range_start) }
          it { expect(model.workout_end_at).to eq(range_end) } 
        end
  
        context 'with an empty date range' do
          before { model.working_period = '' }
  
          it { expect(model.working_period).to be_nil }
          it { expect(model.workout_start_at).to be_nil }
          it { expect(model.workout_end_at).to be_nil }
        end
      end
    end

    context 'when start_attribute and end_attributes are not DB columns' do
      describe '#working_period' do
        before { model.available_period = Time.zone.now.all_day }
  
        it { expect(model.available_period).to eq(Time.zone.now.all_day) }
        it { expect(model.available_from).to eq(Time.zone.now.beginning_of_day) }
        it { expect(model.available_to).to eq(Time.zone.now.end_of_day) }
      end
  
      describe '#working_period=' do
        context 'with range' do
          before { model.available_period = Time.zone.now.all_day }
  
          it { expect(model.available_period).to eq(Time.zone.now.all_day) }
          it { expect(model.available_from).to eq(Time.zone.now.beginning_of_day) }
          it { expect(model.available_to).to eq(Time.zone.now.end_of_day) }
        end
  
        context 'with a valid date range format' do
          let(:range_start) { Time.zone.local(2023, 3, 1) }
          let(:range_end) { Time.zone.local(2023, 3, 10).end_of_day }
  
          before { model.available_period = '2023-03-01 to 2023-03-10' }
  
          it { expect(model.available_period).to eq(range_start..range_end) }
          it { expect(model.available_from).to eq(range_start) }
          it { expect(model.available_to).to eq(range_end) }
        end
  
        context 'with a day as a range' do
          let(:range_start) { Time.zone.local(2023, 3, 1) }
          let(:range_end) { Time.zone.local(2023, 3, 1).end_of_day }
  
          before { model.available_period = '2023-03-01' }

          it { expect(model.available_period).to eq(range_start..range_end) }
          it { expect(model.available_from).to eq(range_start) }
          it { expect(model.available_to).to eq(range_end) } 
        end
  
        context 'with an empty date range' do
          before { model.available_period = '' }
  
          it { expect(model.available_period).to be_nil }
          it { expect(model.available_from).to be_nil }
          it { expect(model.available_to).to be_nil }
        end
      end
    end
  end
end
