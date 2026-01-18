# frozen_string_literal: true

module Bali
  module PropertiesTable
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Displays key-value pairs in a table format with alternating
      # label/value columns. Useful for showing object attributes.
      def default
        render PropertiesTable::Component.new do |c|
          c.with_property(label: 'Name', value: 'John Doe')
          c.with_property(label: 'Email', value: 'john@example.com')
          c.with_property(label: 'Phone', value: '+1 555-1234')
          c.with_property(label: 'Location', value: 'New York, USA')
          c.with_property(label: 'Member Since', value: 'January 2024')
        end
      end

      # @label With Custom Content
      # Properties can accept block content for rich values like tags or links.
      def with_custom_content
        render_with_template
      end
    end
  end
end
