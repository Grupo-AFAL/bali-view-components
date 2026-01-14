module Bali
  module Carousel
    class Preview < ApplicationViewComponentPreview
      SLIDES = [
        { color: '3B82F6', text: 'Slide 1' },
        { color: '10B981', text: 'Slide 2' },
        { color: 'F59E0B', text: 'Slide 3' },
        { color: 'EF4444', text: 'Slide 4' },
        { color: '8B5CF6', text: 'Slide 5' }
      ].freeze

      # Carousel
      # -------------
      # Basic carousel with multiple slides - swipe or use arrows to navigate
      def default
        render(Carousel::Component.new) do |c|
          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/600x400/#{slide[:color]}/FFFFFF?text=#{slide[:text]}", class: 'w-full')
            end
          end
        end
      end

      # Carousel with arrows
      # -------------
      # Carousel with navigation arrows
      def with_arrows
        render(Carousel::Component.new) do |c|
          c.with_arrows

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/600x400/#{slide[:color]}/FFFFFF?text=#{slide[:text]}", class: 'w-full')
            end
          end
        end
      end

      # Carousel with bullets
      # -------------
      # Carousel with bullet pagination
      def with_bullets
        render(Carousel::Component.new) do |c|
          c.with_bullets

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/600x400/#{slide[:color]}/FFFFFF?text=#{slide[:text]}", class: 'w-full')
            end
          end
        end
      end

      # Slider type
      # -------------
      # Shows multiple slides at once
      def slider
        render(Carousel::Component.new(data: { 'carousel-type-value': 'slider' })) do |c|
          c.with_arrows
          c.with_bullets

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/300x200/#{slide[:color]}/FFFFFF?text=#{slide[:text]}", class: 'w-full')
            end
          end
        end
      end

      # Autoplay
      # -------------
      # Carousel with autoplay enabled
      def autoplay
        render(Carousel::Component.new(autoplay: 3000)) do |c|
          c.with_arrows
          c.with_bullets

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/600x400/#{slide[:color]}/FFFFFF?text=#{slide[:text]}", class: 'w-full')
            end
          end
        end
      end
    end
  end
end
