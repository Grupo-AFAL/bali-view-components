# frozen_string_literal: true

module DemoWidgets
  # THE TREND LADDER AT ITS SMALLEST: a figure and a compact delta, no chart.
  # `small` renders the whole tile as one link and nothing inside it may be
  # focusable, so the trend indicator is text rather than a control — and it
  # drops the period label, because a ~215px tile has room for an arrow and a
  # percentage but not for what they compare against.
  class ModernStudios < Bali::Widget::TrendBase
    include WidgetRoutes

    default_size :small

    trend do |t|
      t.current { Studio.where(founded_year: 2000..).count }
      t.previous { Studio.where(founded_year: 1990..1999).count }
      t.period_label "vs the 1990s"
    end

    view_all_path { admin_studios_path }
  end
end
