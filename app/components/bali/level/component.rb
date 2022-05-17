# frozen_string_literal: true

module Bali
  module Level
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :level_left, lambda { |**args|
        Side::Component.new(position: :left, **args)
      }
      renders_one :level_right, lambda { |**args|
        Side::Component.new(position: :right, **args)
      }

      def initialize(**options)
        @class = options.delete(:class)
        @options = options
      end

      def classes
        "level #{@class}"
      end
    end
  end
end
