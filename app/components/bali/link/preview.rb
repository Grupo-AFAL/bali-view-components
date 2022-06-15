# frozen_string_literal: true

module Bali
  module Link
    class Preview < ApplicationViewComponentPreview
      # @!group Button

      # Basic link
      # ----------
      def default
        render Bali::Link::Component.new(name: 'Click me!', href: '#')
      end

      # Link with type prymary
      # ---------------------
      # This will add the class `button` and `is-primary` to the link.
      def primary
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :primary)
      end

      # Link with type secondary
      # -----------------------
      # This will add the class `button` and `is-secondary` to the link.
      def secondary
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :secondary)
      end

      # Link with type success
      # ----------------------
      # This will add the class `button` and `is-success` to the link.
      def success
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :success)
      end

      # Link with type danger
      # ---------------------
      # This will add the class `button` and `is-danger` to the link.
      def danger
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :danger)
      end

      # Link with type warning
      # ---------------------
      # This will add the class `button` and `is-warning` to the link.
      def warning
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :warning)
      end

      # Link with size small
      # ------------------
      # This will change the size of the link to small.
      def small
        render Bali::Link::Component.new(name: 'Small', href: '#', class: 'button is-small')
      end

      # Link with size normal
      # ------------------
      # This will change the size of the link to normal, also this is the default size.
      def normal
        render Bali::Link::Component.new(name: 'Normal', href: '#', class: 'button is-normal')
      end

      # Link with size medium
      # ------------------
      # This will change the size of the link to medium.
      def medium
        render Bali::Link::Component.new(name: 'Medium', href: '#', class: 'button is-medium')
      end

      # Link with size large
      # ------------------
      # This will change the size of the link to large.
      def large
        render Bali::Link::Component.new(name: 'Large', href: '#', class: 'button is-large')
      end

      # Link with icon
      # --------------
      # This will add an icon to the link.
      def with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#') do |c|
          c.icon('poo')
        end
      end

      # Link with icon
      # --------------
      # This will add an icon to the link with class button is-primary.
      def button_with_icon
        render Bali::Link::Component.new(name: 'Click me!', href: '#', type: :primary) do |c|
          c.icon('poo')
        end
      end

      # Link with just an icon
      # --------------
      # This will add an icon to the link but no text.
      def link_with_just_icon
        render Bali::Link::Component.new(href: '#') do |c|
          c.icon('poo')
        end
      end

      # Link with `is-active` class
      # --------------
      # This will add the `is-active` class if the `active_path` is the same as the href.
      def is_active
        render Bali::Link::Component.new(name: 'Click me!', href: '#', active_path: '#',
                                         class: 'button')
      end

      # Link with `data-turbo-method` attribute
      # --------------
      # This will add the `data-turbo-method` attribute to the link.
      def data_turbo_method
        render Bali::Link::Component.new(name: 'Click me!', href: '#', method: :post,
                                         class: 'button')
      end

      # @!endgroup
    end
  end
end
