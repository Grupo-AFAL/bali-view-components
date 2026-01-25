# frozen_string_literal: true

module Bali
  module Card
    class Preview < ApplicationViewComponentPreview
      # @!group Basic

      # Default Card
      # ---------------
      # Basic card view with image, title, description and action.
      # @param style [Symbol] select [default, bordered, dash]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param shadow toggle
      def default(style: :default, size: :md, shadow: true)
        render Card::Component.new(style: style, size: size, shadow: shadow, class: 'w-96') do |c|
          c.with_image(
            src: 'https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp',
            href: '/',
            alt: 'Shoes'
          )

          c.with_title('Card Title')

          c.with_action(href: '#', class: 'btn-primary') do
            'Buy Now'
          end

          tag.p('A card component has a figure, a body part, and inside body there are title and actions parts.')
        end
      end

      # Title Slot
      # ---------------
      # Use `with_title` for simple text titles.
      def with_title
        render Card::Component.new(class: 'w-96') do |c|
          c.with_title('Simple Title')

          tag.p('Use the title slot for simple text titles without extra features.')
        end
      end

      # @!endgroup

      # @!group Headers

      # Basic Header
      # ---------------
      # Use `with_header` for complex headers with subtitle, icon, or badge.
      def with_header
        render Card::Component.new(class: 'w-96') do |c|
          c.with_header(title: 'Header Title', subtitle: 'A helpful subtitle')

          tag.p('Headers support subtitle, icon, and badge slots for richer content.')
        end
      end

      # Header with Icon
      # ---------------
      # Add an icon to draw attention to the card's purpose.
      def header_with_icon
        render Card::Component.new(class: 'w-96') do |c|
          c.with_header(title: 'Settings', subtitle: 'Manage your preferences', icon: 'cog')

          tag.p('Icons help users quickly identify the card\'s purpose.')
        end
      end

      # Header with Badge
      # ---------------
      # Use the badge slot for status indicators or labels.
      def header_with_badge
        render Card::Component.new(class: 'w-96') do |c|
          c.with_header(title: 'Notifications', subtitle: 'Stay up to date') do |header|
            header.with_badge do
              render Bali::Tag::Component.new(text: 'NEW', color: :primary, size: :sm)
            end
          end

          tag.p('Badges can indicate new features, status, or counts.')
        end
      end

      # Complete Header
      # ---------------
      # Header with icon, subtitle, and badge combined.
      def header_complete
        render Card::Component.new(class: 'w-96') do |c|
          c.with_header(title: 'Dashboard', subtitle: 'Overview of your data', icon: 'home') do |header|
            header.with_badge do
              render Bali::Tag::Component.new(text: 'Beta', color: :warning, size: :sm)
            end
          end

          tag.p('Combine icon, subtitle, and badge for information-rich headers.')
        end
      end

      # @!endgroup

      # @!group Styles

      # Bordered Card
      # ---------------
      # Card with border style
      def bordered
        render Card::Component.new(style: :bordered, shadow: false, class: 'w-96') do |c|
          c.with_title('Bordered Card')

          tag.p('This card has a border style instead of shadow.')
        end
      end

      # Dash Card
      # ---------------
      # Card with dashed border
      def dash
        render Card::Component.new(style: :dash, shadow: false, class: 'w-96') do |c|
          c.with_title('Dash Card')

          tag.p('This card has a dashed border style.')
        end
      end

      # Side Layout
      # ---------------
      # Card with side image layout
      def side_layout
        render Card::Component.new(side: true, class: 'max-w-xl') do |c|
          c.with_image(
            src: 'https://img.daisyui.com/images/stock/photo-1635805737707-575885ab0820.webp',
            alt: 'Movie'
          )

          c.with_title('New movie is released!')

          c.with_action(href: '#', class: 'btn-primary') do
            'Watch'
          end

          tag.p('Click the button to watch on Jetflix app.')
        end
      end

      # Image Full
      # ---------------
      # Card with full background image
      def image_full
        render Card::Component.new(image_full: true, class: 'w-96') do |c|
          c.with_image(
            src: 'https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp',
            alt: 'Shoes'
          )

          c.with_title('Full Image Card')

          c.with_action(href: '#', class: 'btn-primary') do
            'Buy Now'
          end

          tag.p('The image covers the entire card background.')
        end
      end

      # @!endgroup

      # @!group Actions

      # Button Actions
      # ---------------
      # Actions without href render as buttons.
      def button_actions
        render Card::Component.new(class: 'w-96') do |c|
          c.with_title('Button Actions')

          c.with_action(class: 'btn-primary', data: { turbo: false, action: 'click->modal#open' }) do
            'Open Modal'
          end

          c.with_action(class: 'btn-ghost') do
            'Cancel'
          end

          tag.p('Actions without href render as buttons with proper btn class.')
        end
      end

      # @!endgroup

      # @!group Custom

      # Custom Image
      # ---------------
      # Card view with custom image module, in this example we use the image with hover effect.
      def custom_image
        render_with_template(template: 'bali/card/previews/custom_image')
      end

      # Image with Figure Class
      # ---------------
      # Use `figure_class` to add padding or styling to the figure wrapper.
      def image_with_figure_class
        render Card::Component.new(class: 'w-96') do |c|
          c.with_image(
            src: 'https://img.daisyui.com/images/stock/photo-1606107557195-0e29a4b5b4aa.webp',
            alt: 'Shoes with padding',
            figure_class: 'px-6 pt-6'
          )

          c.with_title('Padded Image')

          tag.p('Use figure_class to add padding around the image.')
        end
      end

      # @!endgroup
    end
  end
end
