# frozen_string_literal: true

module Bali
  module Dropdown
    class Preview < ApplicationViewComponentPreview
      # Dropdown with items
      # ---------------
      # Default dropdown with a list of items
      # @param hoverable toggle
      # @param close_on_click toggle
      def default(hoverable: false, close_on_click: true)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click)) do |c|
          c.trigger(class: 'button') { 'Trigger' }

          c.item { 'Item 1' }
          c.item { 'Item 2' }
          c.item { 'Item 3' }
          c.item(class: 'has-text-weight-bold') { 'Item with class_name' }
        end
      end

      # Dropdown with any content
      # ---------------
      # Specify any HTML content within the block, it will be inserted
      # inside the div.dropdown-content
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align select[:left, :right, :center]
      def with_content(hoverable: false, close_on_click: true)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click, align: :right)) do |c|
          c.trigger(class: 'button') { 'Trigger' }

          c.tag.ul do
            safe_join([
                        c.tag.li('Item 1'),
                        c.tag.li('Item 2'),
                        c.tag.li('Item 3')
                      ])
          end
        end
      end
    end
  end
end
