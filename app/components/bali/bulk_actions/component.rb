# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :actions, Action::Component
      renders_many :items, Item::Component

      def initialize(**options)
        @options = prepend_class_name(options,
                                      'bulk-actions-component [&_.bulk-actions-component--item.selected]:border [&_.bulk-actions-component--item.selected]:border-info')
        @options = prepend_controller(@options, 'bulk-actions')
      end
    end
  end
end
