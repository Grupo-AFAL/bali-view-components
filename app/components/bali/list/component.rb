# frozen_string_literal: true

module Bali
  module List
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'list-component')
      end
    end
  end
end
