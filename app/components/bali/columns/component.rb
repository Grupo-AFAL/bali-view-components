# frozen_string_literal: true

module Bali
  module Columns
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :columns, Column::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'columns-component grid grid-cols-12 gap-4')
      end
    end
  end
end
