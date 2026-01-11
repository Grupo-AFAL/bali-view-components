# frozen_string_literal: true

module Bali
  module Dropdown
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Dropdown
      # ---------------
      # Dropdown with a list of items
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, top, bottom, top_end, bottom_end]
      # @param wide toggle
      def default(hoverable: false, close_on_click: true, align: :right, wide: false)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click,
                                       align: align, wide: wide)) do |c|
          c.with_trigger(class: 'btn-primary') { 'Click me' }

          c.with_item(href: '#') { 'Item 1' }
          c.with_item(href: '#') { 'Item 2' }
          c.with_item(href: '#') { 'Item 3' }
        end
      end

      # Hoverable Dropdown
      # ---------------
      # Opens on hover using DaisyUI's CSS-only hover
      def hoverable
        render(Dropdown::Component.new(hoverable: true, align: :right)) do |c|
          c.with_trigger(class: 'btn-secondary') { 'Hover me' }

          c.with_item(href: '#') { 'Item 1' }
          c.with_item(href: '#') { 'Item 2' }
        end
      end

      # @!endgroup

      # @!group Alignments

      # Dropdown Top
      # ---------------
      # Opens above the trigger
      def top_aligned
        render(Dropdown::Component.new(align: :top)) do |c|
          c.with_trigger(class: 'btn-accent') { 'Open Up' }

          c.with_item(href: '#') { 'Item 1' }
          c.with_item(href: '#') { 'Item 2' }
        end
      end

      # Dropdown Bottom End
      # ---------------
      # Opens below aligned to the end
      def bottom_end_aligned
        render(Dropdown::Component.new(align: :bottom_end)) do |c|
          c.with_trigger(class: 'btn-info') { 'Bottom End' }

          c.with_item(href: '#') { 'Item 1' }
          c.with_item(href: '#') { 'Item 2' }
        end
      end

      # @!endgroup

      # @!group Content

      # With Custom Content
      # ---------------
      # Specify any HTML content within the block
      # @param hoverable toggle
      # @param close_on_click toggle
      # @param align [Symbol] select [left, right, top, bottom, top_end, bottom_end]
      def with_content(hoverable: false, close_on_click: true, align: :right)
        render(Dropdown::Component.new(hoverable: hoverable, close_on_click: close_on_click,
                                       align: align)) do |c|
          c.with_trigger(class: 'btn-ghost') { 'Custom Content' }

          c.tag.li do
            c.tag.div(class: 'p-4') do
              c.tag.h3('Dropdown Title', class: 'font-bold text-lg') +
                c.tag.p('This is custom HTML content inside the dropdown.',
                        class: 'text-sm opacity-70')
            end
          end
        end
      end

      # Wide Dropdown
      # ---------------
      # Wider dropdown menu for more content
      def wide
        render(Dropdown::Component.new(wide: true)) do |c|
          c.with_trigger(class: 'btn-warning') { 'Wide Menu' }

          c.with_item(href: '#') { 'This is a longer menu item' }
          c.with_item(href: '#') { 'Another longer menu item here' }
          c.with_item(href: '#') { 'Third item with more text' }
        end
      end

      # @!endgroup
    end
  end
end
