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
      c.header(period: c.period, start_date: '2020-01-01')
    end

    expect(rendered_component).to have_css '.calendar-component'
    expect(rendered_component).to have_css '.month-view'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Sunday'
    expect(rendered_component).to have_css '.header > .columns > .column > h3.title',
                                           text: 'January 2020'
  end

  it 'renders calendar component from monday to friday' do
    @options.merge!(start_date: '2020-01-01', all_week: false)
    render_inline(component)

    expect(rendered_component).to have_css '.calendar-component'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Tuesday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Wednesday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Thursday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(rendered_component).not_to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(rendered_component).not_to have_css 'tr > th.has-text-centered', text: 'Sunday'
  end

  it 'renders the calendar component hiding the calendar view options' do
    @options.merge!(start_date: '2020-01-01', period_switch: false)
    render_inline(component) do |c|
      c.header(period: c.period, start_date: '2020-01-01', period_switch: false)
    end

    expect(rendered_component).to have_css '.calendar-component'
    expect(rendered_component).to have_css '.header > .columns > .column > h3.title',
                                           text: 'January 2020'
    expect(rendered_component).not_to have_css '.header > .columns > .column > a.button',
                                               text: 'Semana'
    expect(rendered_component).not_to have_css '.header > .columns > .column > a.button',
                                               text: 'Mes'
  end

  it 'renders the calendar component with week view' do
    @options.merge!(start_date: '2020-01-01', period: :week)
    render_inline(component)

    expect(rendered_component).to have_css '.calendar-component'
    expect(rendered_component).to have_css '.week-view'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Monday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Tuesday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Wednesday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Thursday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Friday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Saturday'
    expect(rendered_component).to have_css 'tr > th.has-text-centered', text: 'Sunday'
  end

  describe '#prev_date' do
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

  describe '#next_date' do
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
end
