# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Preview < ApplicationViewComponentPreview
      def default
        render PropertiesTable::Component.new do |c|
          c.with_property(label: 'Label 1', value: 'Value 1')
          c.with_property(label: 'Label 2', value: 'Value 2')
          c.with_property(label: 'Label 3', value: 'Value 3')
          c.with_property(label: 'Label 4', value: 'Value 4')
          c.with_property(label: 'Label 5', value: 'Value 5')
        end
      end
    end
  end
end
