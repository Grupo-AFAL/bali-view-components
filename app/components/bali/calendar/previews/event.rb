# frozen_string_literal: true

module Bali
  module Calendar
    module Previews
      # A stand-in event for the Lookbook previews. `status` is deliberately
      # nothing but a name from Bali::Color::NAMES: the calendar carries no
      # vocabulary of its own about what an event *is*, and neither should the
      # object the preview feeds it.
      #
      # `url` is the event's OWN destination, and it is not the same thing as the
      # calendar's `day_url`. `day_url` links the day cell — one link for the
      # whole square, drawn in the grid. This one links one event inside the
      # host's partial, so the year view's hover card opens the item itself
      # rather than the day it happens to sit on. Both may be present; they are
      # different questions.
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
