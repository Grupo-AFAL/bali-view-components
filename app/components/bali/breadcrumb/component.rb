# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'breadcrumb breadcrumb-component')
      end
    end
  end
end
