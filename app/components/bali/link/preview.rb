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

      def small
        render Bali::Link::Component.new(name: 'Small', href: '#', class: 'button is-small')
      end

      def normal
        render Bali::Link::Component.new(name: 'Normal', href: '#', class: 'button is-normal')
      end

      def medium
        render Bali::Link::Component.new(name: 'Medium', href: '#', class: 'button is-medium')
      end

      def large
        render Bali::Link::Component.new(name: 'Large', href: '#', class: 'button is-large')
      end

      def with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#') do |c|
          c.icon('poo')
        end
      end

      def button_with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :primary) do |c|
          c.icon('poo')
        end
      end
      # @!endgroup
    end
  end
end
