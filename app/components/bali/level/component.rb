# frozen_string_literal: true

module Bali
  module Level
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :left, ->(**args) do
        Side::Component.new(position: :left, **args)
      end
      renders_one :right, ->(**args) do
        Side::Component.new(position: :right, **args)
      end

      renders_many :items, Item::Component

      def initialize(align: :center, **options)
        @align = align
        @options = prepend_class_name(options, "level align-#{align}")
      end
    end
  end
end
