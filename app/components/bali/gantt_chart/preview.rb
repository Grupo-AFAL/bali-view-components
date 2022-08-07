# frozen_string_literal: true

module Bali
  module GanttChart
    class Preview < ApplicationViewComponentPreview
      def default
        render GanttChart::Component.new
      end
    end
  end
end
