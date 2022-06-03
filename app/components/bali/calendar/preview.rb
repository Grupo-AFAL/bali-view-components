# frozen_string_literal: true

module Bali
  module Calendar
    class Preview < ApplicationViewComponentPreview
      def default
        render(Calendar::Component.new(
                 start_date: Date.current.to_s,
                 all_week: false,
                 show_date: true
               )) do |c|
          c.header(start_date: Date.current.to_s)
        end
      end

      def week
        render(
          Calendar::Component.new(start_date: Date.current.to_s,
                                  all_week: false,
                                  period: :week,
                                  show_date: true)
        ) do |c|
          c.header(start_date: Date.current.to_s)
        end
      end
    end
  end
end
