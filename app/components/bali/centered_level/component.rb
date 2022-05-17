# frozen_string_literal: true

module Bali
  module CenteredLevel
    class Component < ApplicationViewComponent
      renders_many :items, Item::Component

      def initialize(**options)
        @class = options.delete(:class)
        @options = options
      end

      def classes
        class_names('level', @class)
      end
    end
  end
end
