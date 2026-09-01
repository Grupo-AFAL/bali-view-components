# frozen_string_literal: true

module Bali
  module Calendar
    module Previews
      # A stand-in event for the Lookbook previews. `status` is deliberately
      # nothing but a name from Bali::Color::NAMES: the calendar carries no
      # vocabulary of its own about what an event *is*, and neither should the
      # object the preview feeds it.
      class Event
        attr_reader :start_time, :end_time, :name, :status

        def initialize(start_time: nil, end_time: nil, name: nil, status: nil)
          @start_time = start_time
          @end_time = end_time
          @name = name
          @status = status
        end
      end
    end
  end
end
