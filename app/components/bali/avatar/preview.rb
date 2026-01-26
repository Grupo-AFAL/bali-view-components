# frozen_string_literal: true

module Bali
  module Avatar
    class Preview < ApplicationViewComponentPreview
      # Default Avatar
      # ----------------
      # Basic avatar with circle shape (default)
      def default
        render_with_template(
          template: 'bali/avatar/previews/default'
        )
      end

      # All Shapes
      # ----------------
      # Avatar component in all available shapes: square, rounded, circle
      def all_shapes
        render_with_template(
          template: 'bali/avatar/previews/all_shapes'
        )
      end

      # All Sizes
      # ----------------
      # Avatar component in all available sizes: xs, sm, md, lg, xl
      def all_sizes
        render_with_template(
          template: 'bali/avatar/previews/all_sizes'
        )
      end

      # With Mask
      # ----------------
      # Avatar with creative mask shapes
      # @param mask select [heart, squircle, hexagon, triangle, diamond, pentagon, star]
      def with_mask(mask: :squircle)
        render_with_template(
          template: 'bali/avatar/previews/with_mask',
          locals: { mask: mask.to_sym }
        )
      end

      # All Masks
      # ----------------
      # Showcase all available mask shape options
      def all_masks
        render_with_template(
          template: 'bali/avatar/previews/all_masks'
        )
      end

      # With Placeholder
      # ----------------
      # Avatar with text initials instead of image
      # @param initials text
      # @param size select [xs, sm, md, lg, xl]
      def with_placeholder(initials: 'JD', size: :md)
        render_with_template(
          template: 'bali/avatar/previews/with_placeholder',
          locals: { initials: initials, size: size.to_sym }
        )
      end

      # Avatar Group
      # ----------------
      # Multiple avatars grouped together with overlap
      # @param spacing select [tight, normal, loose]
      def avatar_group(spacing: :normal)
        render_with_template(
          template: 'bali/avatar/previews/avatar_group',
          locals: { spacing: spacing.to_sym }
        )
      end

      # Avatar Group with Counter
      # ----------------
      # Avatar group with a counter showing remaining count
      def avatar_group_with_counter
        render_with_template(
          template: 'bali/avatar/previews/avatar_group_with_counter'
        )
      end

      # With Ring
      # ----------------
      # Avatar with decorative ring border in various colors
      # @param ring select [primary, secondary, accent, neutral, success, warning, error, info]
      def with_ring(ring: :primary)
        render_with_template(
          template: 'bali/avatar/previews/with_ring',
          locals: { ring: ring.to_sym }
        )
      end

      # With Presence Indicator
      # ----------------
      # Avatar showing online/offline status indicator
      # @param status select [online, offline]
      def with_presence(status: :online)
        render_with_template(
          template: 'bali/avatar/previews/with_presence',
          locals: { status: status.to_sym }
        )
      end

      # With Custom Image
      # ----------------
      # Avatar with a pre-loaded custom image using the picture slot
      # @param image_url text
      def with_image(image_url: 'avatar.png')
        render_with_template(
          template: 'bali/avatar/previews/with_image',
          locals: { image_url: image_url }
        )
      end

      # All Ring Colors
      # ----------------
      # Showcase all available ring color options
      def all_ring_colors
        render_with_template(
          template: 'bali/avatar/previews/all_ring_colors'
        )
      end

      # With Upload
      # ----------------
      # Avatar with file upload functionality using `Avatar::Upload::Component`.
      # Requires a form context. The upload component wraps the display Avatar
      # and adds a camera button overlay.
      # @param size select [xs, sm, md, lg, xl]
      # @param shape select [square, rounded, circle]
      def with_upload(size: :xl, shape: :circle)
        render_with_template(
          template: 'bali/avatar/previews/with_upload',
          locals: { size: size.to_sym, shape: shape.to_sym }
        )
      end

      # Combined Features
      # ----------------
      # Avatar combining size, shape, ring, and presence indicator
      # @param size select [xs, sm, md, lg, xl]
      # @param shape select [square, rounded, circle]
      # @param ring select [~, primary, secondary, accent, success, error]
      # @param status select [~, online, offline]
      def combined(size: :md, shape: :circle, ring: nil, status: nil)
        render_with_template(
          template: 'bali/avatar/previews/combined',
          locals: {
            size: size.to_sym,
            shape: shape.to_sym,
            ring: ring.presence&.to_sym,
            status: status.presence&.to_sym
          }
        )
      end
    end
  end
end
