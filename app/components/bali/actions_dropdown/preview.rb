# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Preview < ApplicationViewComponentPreview
      # Default Actions Dropdown
      # ---------------
      # Dropdown menu for row-level actions with icon trigger.
      # Items with `method: :delete` automatically use DeleteLink with confirmation.
      def default
        render_with_template
      end

      # @param align select { choices: [start, center, end] }
      # @param direction select { choices: [~, top, bottom, left, right] }
      # @param width select { choices: [sm, md, lg, xl] }
      # Playground
      # ---------------
      # Explore different alignments, directions, and widths.
      # **Alignment** controls horizontal position (start/center/end).
      # **Direction** controls where menu opens (top/bottom/left/right).
      # **Width** controls menu width (sm=10rem, md=13rem, lg=16rem, xl=20rem).
      def playground(align: :start, direction: nil, width: :md)
        render_with_template(locals: {
          align: align.to_sym,
          direction: direction.presence&.to_sym,
          width: width.to_sym
        })
      end

      # With Custom Trigger
      # ---------------
      # Override the default ellipsis icon with a custom trigger button.
      # Use `with_trigger` slot to provide any element as the dropdown trigger.
      def with_custom_trigger
        render_with_template
      end

      # With Custom Icon
      # ---------------
      # Change the default trigger icon using the `icon` parameter.
      # Useful when you want vertical ellipsis or another icon.
      def with_custom_icon
        render_with_template
      end

      # With Custom Content
      # ---------------
      # Pass block content directly for full control over menu items.
      # Use this when items slot doesn't fit your needs.
      def with_custom_content
        render_with_template
      end
    end
  end
end
