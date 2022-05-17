# frozen_string_literal: true

module Bali
  module InfoLevel
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'info-level-component level', )
      end
    end
  end
end
