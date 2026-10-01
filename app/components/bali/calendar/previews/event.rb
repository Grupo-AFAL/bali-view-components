# frozen_string_literal: true

module Bali
  module Calendar
    module Previews
      # `status` is a Bali::Color name; `url` is the event's own link, distinct
      # from the calendar's `day_url`.
      class Event
        attr_reader :start_time, :end_time, :name, :status, :url

        def initialize(start_time: nil, end_time: nil, name: nil, status: nil, url: nil)
          @start_time = start_time
          @end_time = end_time
          @name = name
          @status = status
          @url = url
        end
      end
    end
  end
end
