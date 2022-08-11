# frozen_string_literal: true

module Bali
  module GanttChart
    module TimelineHeader
      class Component < ApplicationViewComponent
        attr_reader :start_date, :end_date, :col_width, :zoom

        def initialize(start_date:, end_date:, col_width:, zoom:)
          @start_date = start_date
          @end_date = end_date
          @col_width = col_width
          @zoom = zoom
        end

        def days_by_month
          @days_by_month ||= date_range.group_by(&:month)
        end

        def months_by_year
          @months_by_year ||= date_range.select { |d| d.day == 1 }.group_by(&:year)
        end

        def weeks_by_year
          @weeks_by_year ||= date_range.select { |d| d.wday == 1 }.group_by(&:year)
        end

        private

        def date_range
          start_date..end_date
        end
      end
    end
  end
end
