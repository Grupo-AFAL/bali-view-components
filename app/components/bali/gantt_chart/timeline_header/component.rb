module Bali
  module GanttChart
    module TimelineHeader
      class Component < ApplicationViewComponent
        attr_reader :days_by_month, :col_width

        def initialize(days_by_month:, col_width:)
          @days_by_month = days_by_month
          @col_width = col_width
        end
      end
    end
  end
end
