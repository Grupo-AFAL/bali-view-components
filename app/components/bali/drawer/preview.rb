# frozen_string_literal: true

module Bali
  module Drawer
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size select [narrow, medium, wide, extra_wide]
      # @param position select [left, right]
      def default(active: true, size: :medium, position: :right)
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
      def with_slots(active: true)
        render Bali::Drawer::Component.new(active: active, size: :medium) do |drawer|
          drawer.with_header do
            tag.h2('Custom Header', class: 'text-lg font-bold')
          end

          drawer.with_footer do
            safe_join([
              render(Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'drawer#close' })),
              render(Bali::Button::Component.new(name: 'Save', variant: :primary))
            ], ' ')
          end

          tag.div(class: 'space-y-4') do
            safe_join([
              tag.p('Main content goes here. Use slots to customize the drawer layout.'),
              tag.p('The footer slot is perfect for action buttons.')
            ])
          end
        end
      end

      # All Sizes
      # ---
      # Available sizes: narrow, medium, wide, extra_wide.
      # @param size select [narrow, medium, wide, extra_wide]
      def sizes(size: :medium)
        render Bali::Drawer::Component.new(
          active: true,
          size: size.to_sym,
          title: "#{size.to_s.titleize} Drawer"
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
