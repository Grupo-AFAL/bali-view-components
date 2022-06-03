# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # @!group Button

      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end
      
      def primary
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :primary)
      end

      def secondary
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :secondary)
      end

      def success
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :success)
      end

      def danger
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :danger)
      end

      def warning
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :warning)
      end

      def with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#') do |c|
          c.icon(class: 'icon') do
            '<svg width="13" height="13" viewBox="0 0 13 13" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path fill-rule="evenodd" clip-rule="evenodd" d="M12.1728 2.75329C12.4328 3.01329 12.4328 3.43329 12.1728 3.69329L10.9528 4.91329L8.4528 2.41329L9.6728 1.19329C9.9328 0.933291 10.3528 0.933291 10.6128 1.19329L12.1728 2.75329ZM0.366211 12.9999V10.4999L7.73954 3.12655L10.2395 5.62655L2.86621 12.9999H0.366211Z" fill="#00AA92"/>
            </svg>'.html_safe
          end
        end
      end
      # @!endgroup
    end
  end
end
