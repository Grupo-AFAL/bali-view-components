# frozen_string_literal: true

class PagesController < ApplicationController
  layout :choose_layout

  # Simple struct for calendar event demo data
  CalendarEvent = Struct.new(:start_time, :end_time, :title, keyword_init: true)

  private

  def choose_layout
    case action_name
    when 'landing' then 'marketing'
    # Bali::AppLayout renders its own <body>, so the shell around it must not have one.
    # That is what 'app_layout_preview' is for, and the AppLayout previews use it too.
    when 'sidemenu_example' then 'app_layout_preview'
    when 'workspace' then 'admin'
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
    # Full-page SideMenu reference; the shell comes from `choose_layout` above.
  end

  def workspace
    # Reference page demonstrating the standard "navbar + sidebar + content" admin shell.
    @stats = [
      { label: 'Total Movies', value: Movie.count, change: '+12.5%', icon: 'film', color: 'primary' },
      { label: 'Studios', value: Tenant.count, change: '+3.2%', icon: 'building-2', color: 'secondary' },
      { label: 'Revenue', value: '$45.2K', change: '+18.1%', icon: 'dollar-sign', color: 'success' },
      { label: 'Active Users', value: 892, change: '-2.4%', icon: 'users', color: 'info' }
    ]
    @recent_movies = Movie.includes(:studio).order(created_at: :desc).limit(6)
  end
end
