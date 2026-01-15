# frozen_string_literal: true

module Bali
  module BulkActions
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :actions, Action::Component
      renders_many :items, Item::Component

      ITEM_SELECTED_CLASSES = '[&_.bulk-actions-component--item.selected]:border ' \
                              '[&_.bulk-actions-component--item.selected]:border-info'

      def initialize(**options)
        @options = prepend_class_name(options, "bulk-actions-component #{ITEM_SELECTED_CLASSES}")
        @options = prepend_controller(@options, 'bulk-actions')
      end
    end
  end
end
