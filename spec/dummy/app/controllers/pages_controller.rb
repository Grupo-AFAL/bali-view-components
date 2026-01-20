# frozen_string_literal: true

class PagesController < ApplicationController
  layout :choose_layout

  # Simple struct for calendar event demo data
  CalendarEvent = Struct.new(:start_time, :end_time, :title, keyword_init: true)

  private

  def choose_layout
    case action_name
    when 'landing' then 'marketing'
    when 'sidemenu_example' then 'lookbook_preview' # Minimal layout for full-page demo
    else 'application'
    end
  end

  public

  def landing
    # Stats for marketing page
    @movies_count = Movie.count
    @studios_count = Tenant.count
  end

  def showcase
    # Calendar events demo data
    @calendar_events = [
      CalendarEvent.new(start_time: Date.current, end_time: Date.current, title: 'Today'),
      CalendarEvent.new(start_time: Date.current + 3.days, end_time: Date.current + 3.days, title: 'Meeting'),
      CalendarEvent.new(start_time: Date.current + 7.days, end_time: Date.current + 9.days, title: 'Conference')
    ]
  end

  def sidemenu_example
    # Uses application layout by default (inherits from layout setting)
  end
end
