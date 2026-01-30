# frozen_string_literal: true

module Bali
  module Drawer
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size select [sm, md, lg, xl, full]
      # @param position select [left, right]
      def default(active: true, size: :md, position: :right)
        render Bali::Drawer::Component.new(
          active: active,
          size: size.to_sym,
          position: position.to_sym,
          title: 'Drawer Title'
        ) do
          tag.p('This is the drawer content. It slides in from the side of the screen.',
                class: 'text-base-content')
        end
      end

      # With Header and Footer Slots
      # ---
      # Use slots for custom header and footer content.
      # The header slot replaces the default title.
      # @param active toggle
      def with_slots(active: true)
        render_with_template(locals: { active: active })
      end

      # All Sizes
      # ---
      # Available sizes: sm, md, lg, xl, full.
      # @param size select [sm, md, lg, xl, full]
      def sizes(size: :md)
        render Bali::Drawer::Component.new(
          active: true,
          size: size.to_sym,
          title: "#{size.to_s.upcase} Drawer"
        ) do
          tag.p("This drawer uses the #{size} size (#{Bali::Drawer::Component::SIZES[size.to_sym]}).",
                class: 'text-base-content')
        end
      end

      # Left Position
      # ---
      # Drawer opens from the left side.
      def left_position(active: true)
        render Bali::Drawer::Component.new(
          active: active,
          position: :left,
          title: 'Left Drawer'
        ) do
          tag.p('This drawer slides in from the left side of the screen.',
                class: 'text-base-content')
        end
      end
    end
  end
end
