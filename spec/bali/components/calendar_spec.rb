# frozen_string_literal: true

require 'rails_helper'

describe Bali::Calendar::Component, type: :component do
  before do
    @options = {}
  end

  let(:component) { Bali::Calendar::Component.new(**@options) }
  let(:monday) { Date.current.prev_occurring(:monday) }
  let(:friday) { Date.current.prev_occurring(:friday) }

  it 'renders calendar component with all week' do
    @options.merge!(start_date: '2020-01-01', all_week: true)
    render_inline(component) do |c|
      c.with_header(period: c.period, start_date: '2020-01-01')
    end

    expect(page).to have_css '.calendar-component'
    expect(page).to have_css '.month-view'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Sunday'
    expect(page).to have_css '.header > .columns > .column > h3.title',
                             text: 'January 2020'
  end

  it 'renders calendar component from monday to friday' do
    @options.merge!(start_date: '2020-01-01', all_week: false)
    render_inline(component)

    expect(page).to have_css '.calendar-component'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Tuesday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Wednesday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Thursday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(page).not_to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(page).not_to have_css 'tr > th.has-text-centered', text: 'Sunday'
  end

  it 'renders the calendar component hiding the calendar view options' do
    @options.merge!(start_date: '2020-01-01', period_switch: false)
    render_inline(component) do |c|
      c.with_header(period: c.period, start_date: '2020-01-01', period_switch: false)
    end

    expect(page).to have_css '.calendar-component'
    expect(page).to have_css '.header > .columns > .column > h3.title',
                             text: 'January 2020'
    expect(page).not_to have_css '.header > .columns > .column > a.button',
                                 text: 'Week'
    expect(page).not_to have_css '.header > .columns > .column > a.button',
                                 text: 'Month'
  end

  it 'renders the calendar component with week view' do
    @options.merge!(start_date: '2020-01-01', period: :week)
    render_inline(component)

    expect(page).to have_css '.calendar-component'
    expect(page).to have_css '.week-view'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Tuesday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Wednesday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Thursday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(page).to have_css 'tr > th.has-text-centered', text: 'Sunday'
  end

  describe '#prev_day' do
    context 'when the start_date is monday' do
      context 'when all_week is true' do
        it 'returns the previous day' do
          @options.merge!(start_date: monday.to_s, all_week: true)

          expect(component.prev_day).to eq({ start_time: monday - 1.day })
        end
      end

      context 'when all_week is false' do
        it 'returns the previous friday' do
          @options.merge!(start_date: monday.to_s, all_week: false)

          expect(component.prev_day).to eq({ start_time: monday - 3.days })
        end
      end
    end

    context 'when the start_date is not monday' do
      it 'returns the previous day' do
        @options.merge!(start_date: friday.to_s)

        expect(component.prev_day).to eq({ start_time: friday - 1.day })
      end
    end
  end

  describe '#next_day' do
    context 'when the start_date is friday' do
      context 'when all_week is true' do
        it 'returns the next day' do
          @options.merge!(start_date: friday.to_s, all_week: true)

          expect(component.next_day).to eq({ start_time: friday + 1.day })
        end
      end

      context 'when all_week is false' do
        it 'returns the next monday' do
          @options.merge!(start_date: friday.to_s, all_week: false)

          expect(component.next_day).to eq({ start_time: friday + 3.days })
        end
      end

      context 'when the start_date is not friday' do
        it 'returns the next day' do
          @options.merge!(start_date: monday.to_s)

          expect(component.next_day).to eq({ start_time: monday + 1.day })
        end
      end
    end
  end

  describe '#prev_start_date' do
    context 'when the period is month' do
      it 'returns the first date of the last month' do
        prev_date = Date.current

        render_inline(component) do |c|
          prev_date = c.with_header(start_date: '2020-03-03').prev_start_date
        end

        expect(prev_date).to eq(Date.parse('2020-02-01'))
      end
    end

    context 'when the period is week' do
      it 'returns the first date of the previous week' do
        prev_date = Date.current

        render_inline(component) do |c|
          prev_date = c.with_header(start_date: '2020-03-03', period: :week).prev_start_date
        end

        expect(prev_date).to eq(Date.parse('2020-02-24'))
      end
    end
  end

  describe '#next_start_date' do
    context 'when the period is month' do
      it 'returns the first date of the next month' do
        next_date = Date.current

        render_inline(component) do |c|
          next_date = c.with_header(start_date: '2020-03-03').next_start_date
        end

        expect(next_date).to eq(Date.parse('2020-04-01'))
      end
    end

    context 'when the period is week' do
      it 'returns the first date of the next week' do
        next_date = Date.current

        render_inline(component) do |c|
          next_date = c.with_header(start_date: '2020-03-03', period: :week).next_start_date
        end

        expect(next_date).to eq(Date.parse('2020-03-09'))
      end
    end
  end

  describe '#extra_params' do
    it 'returns params for going back in the calendar' do
      params = {}

      render_inline(component) do |c|
        params = c.with_header(start_date: '2020-02-02').extra_params(:prev)
      end

      expect(params).to eq({ start_time: Date.parse('2020-01-01'), period: :month })
    end

    it 'returns params for going forward in the calendar' do
      params = {}

      render_inline(component) do |c|
        params = c.with_header(start_date: '2020-02-02').extra_params(:next)
      end

      expect(params).to eq({ start_time: Date.parse('2020-03-01'), period: :month })
    end

    it 'returns params for change the view to month in the calendar' do
      params = {}

      render_inline(component) do |c|
        params = c.with_header(start_date: '2020-02-02').extra_params(:month)
      end

      expect(params).to eq({ start_time: Date.parse('2020-02-02'), period: 'month' })
    end

    it 'returns params for change the view to week in the calendar' do
      params = {}

      render_inline(component) do |c|
        params = c.with_header(start_date: '2020-02-02').extra_params(:week)
      end

      expect(params).to eq({ start_time: Date.parse('2020-02-02'), period: 'week' })
    end
  end

  describe '#sorted_events' do
    it 'returns the events sorted and gruped by start_time' do
      key1 = Struct.new(:start_time)
      key2 = Struct.new(:start_time)
      value1 = key1.new(Date.parse('2020-02-02'))
      value2 = key2.new(Date.parse('2020-02-01'))

      events = [value1, value2]
      @options.merge!(events: events)

      expect(component.sorted_events.keys).to eq([Date.parse('2020-02-01'),
                                                  Date.parse('2020-02-02')])
    end
  end
end
