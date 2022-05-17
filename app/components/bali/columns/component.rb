# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :columns, Column::Component

      def initialize(**options)
        @class = options.delete(:class)
        @options = options
      end

      def classes
        "columns-component columns #{@class}"
      end
    end
  end
end
