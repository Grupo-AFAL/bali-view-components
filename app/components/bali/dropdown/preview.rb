# frozen_string_literal: true

module Bali
  module Dropdown
    class Preview < ApplicationViewComponentPreview
      # Dropdown with items
      # ---------------
      # Default dropdown with a list of items
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, up]
      def default(hoverable: false, close_on_click: true, align: :left)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click, align: align)) do |c|
          c.with_trigger(class: 'button') { 'Trigger' }

          c.with_item { 'Item 1' }
          c.with_item { 'Item 2' }
          c.with_item { 'Item 3' }
          c.with_item(class: 'has-text-weight-bold') { 'Item with class_name' }
        end
      end

      # Dropdown with any content
      # ---------------
      # Specify any HTML content within the block, it will be inserted
      # inside the div.dropdown-content
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, up]
      def with_content(hoverable: false, close_on_click: true, align: :left)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click, align: align)) do |c|
          c.with_trigger(class: 'button') { 'Trigger' }

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
