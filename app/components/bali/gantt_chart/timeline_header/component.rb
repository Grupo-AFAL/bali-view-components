module Bali
  module GanttChart
    module TimelineHeader
      class Component < ApplicationViewComponent
        attr_reader :start_date, :end_date, :col_width

        def initialize(start_date:, end_date:, col_width:)
          @start_date = start_date
          @end_date = end_date
          @col_width = col_width
        end

        def days_by_month
          @days_by_month ||= (start_date..end_date).group_by(&:month)
        end
      end
    end
  end
end
