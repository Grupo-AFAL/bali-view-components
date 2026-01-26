# frozen_string_literal: true

module Bali
  module List
    class Preview < ApplicationViewComponentPreview
      # @param borderless toggle
      # @param relaxed_spacing toggle
      def default(borderless: false, relaxed_spacing: false)
        render List::Component.new(borderless: borderless, relaxed_spacing: relaxed_spacing) do |c|
          c.with_item do |i|
            i.with_title('First item')
            i.with_subtitle('Description of the first item')
          end
          c.with_item do |i|
            i.with_title('Second item with custom class', class: 'text-success')
            i.with_subtitle('Description of the second item')
          end
          c.with_item do |i|
            i.with_title do
              tag.a('Third item as a link', href: '#')
            end
            i.with_subtitle do
              tag.p('Description with block content', class: 'text-info')
            end
          end
        end
      end

      def with_actions
        render List::Component.new do |c|
          c.with_item do |i|
            i.with_title('Item with delete action')
            i.with_subtitle('Click the button to delete')
            i.with_action do
              c.render(Bali::Button::Component.new(
                name: 'Delete',
                variant: :error,
                size: :sm,
                icon: 'trash'
              ))
            end
          end

          c.with_item do |i|
            i.with_title('Item with multiple actions')
            i.with_subtitle('Edit or delete this item')
            i.with_action do
              c.render(Bali::Button::Component.new(
                name: 'Edit',
                variant: :ghost,
                size: :sm,
                icon: 'pencil'
              ))
            end
            i.with_action do
              c.render(Bali::Button::Component.new(
                name: 'Delete',
                variant: :error,
                size: :sm,
                outline: true,
                icon: 'trash'
              ))
            end
          end
        end
      end

      def with_content
        render List::Component.new do |c|
          c.with_item do |i|
            i.with_title('Item with additional content')
            i.with_subtitle('Main description')
            i.with_action do
              c.render(Bali::Button::Component.new(
                name: 'Delete',
                variant: :ghost,
                size: :sm,
                icon: 'trash'
              ))
            end

            tag.p('This is additional content that appears in the middle column')
          end

          c.with_item do |i|
            i.with_title('Another item')
            i.with_subtitle('With extra details')
            i.with_action do
              c.render(Bali::Button::Component.new(
                name: 'Remove',
                variant: :ghost,
                size: :sm,
                icon: 'x'
              ))
            end

            tag.span('Extra information displayed here', class: 'badge badge-info')
          end
        end
      end

      def borderless
        render List::Component.new(borderless: true) do |c|
          c.with_item do |i|
            i.with_title('First item')
            i.with_subtitle('No outer border')
          end
          c.with_item do |i|
            i.with_title('Second item')
            i.with_subtitle('Clean appearance')
          end
          c.with_item do |i|
            i.with_title('Third item')
            i.with_subtitle('Minimal styling')
          end
        end
      end

      def relaxed_spacing
        render List::Component.new(relaxed_spacing: true) do |c|
          c.with_item do |i|
            i.with_title('Item with more padding')
            i.with_subtitle('Relaxed spacing for better readability')
          end
          c.with_item do |i|
            i.with_title('Another spaced item')
            i.with_subtitle('More vertical breathing room')
          end
        end
      end
    end
  end
end
