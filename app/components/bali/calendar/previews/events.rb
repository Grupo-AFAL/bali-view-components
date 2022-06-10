# frozen_string_literal: true

module Bali
  module Calendar
    module Previews
      class Events
        attr_reader :start_time, :name

        def initialize(start_time: nil, name: nil)
          @start_time = start_time
          @name = name
        end
      end
    end
  end
end
