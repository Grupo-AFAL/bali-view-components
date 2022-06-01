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

      renders_many :items, Item::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'level')
      end
    end
  end
end
