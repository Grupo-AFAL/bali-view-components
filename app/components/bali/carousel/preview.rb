# frozen_string_literal: true

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

      # @param with_arrows toggle
      # @param with_bullets toggle
      # @param slides_per_view select { choices: [1, 2, 3] }
      # @param autoplay select { choices: [disabled, slow, medium, fast] }
      # @param gap select { choices: [0, 8, 16, 24] }
      def default(with_arrows: true, with_bullets: true, slides_per_view: 1, autoplay: :disabled, gap: 0)
        render(Carousel::Component.new(
                 slides_per_view: slides_per_view.to_i,
                 autoplay: autoplay.to_sym,
                 gap: gap.to_i
               )) do |c|
          c.with_arrows if with_arrows
          c.with_bullets if with_bullets

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/600x400/#{slide[:color]}/FFFFFF?text=#{slide[:text]}",
                        class: 'w-full rounded-lg')
            end
          end
        end
      end

      # @label Slider (Multiple Visible)
      # Shows multiple slides at once with slider type.
      # Useful for product carousels or thumbnail galleries.
      def slider
        render(Carousel::Component.new(
                 slides_per_view: 3,
                 gap: 16,
                 data: { 'carousel-type-value': 'slider' }
               )) do |c|
          c.with_arrows
          c.with_bullets

          SLIDES.each do |slide|
            c.with_item do
              image_tag("https://placehold.co/300x200/#{slide[:color]}/FFFFFF?text=#{slide[:text]}",
                        class: 'w-full rounded-lg')
            end
          end
        end
      end
    end
  end
end
