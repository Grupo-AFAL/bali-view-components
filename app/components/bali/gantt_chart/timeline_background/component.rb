# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineBackground
      class Component < ApplicationViewComponent
        include DateRanges

        attr_reader :start_date, :end_date, :col_width, :zoom

        def initialize(start_date:, end_date:, col_width:, zoom:)
          @start_date = start_date
          @end_date = end_date
          @col_width = col_width
          @zoom = zoom
          @position = 0
        end
      end
    end
  end
end
