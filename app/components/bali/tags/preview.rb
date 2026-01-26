# frozen_string_literal: true

module Bali
  module Tags
    class Preview < ApplicationViewComponentPreview
      # @param gap select { choices: [none, xs, sm, md, lg] }
      def default(gap: :sm)
        render Tags::Component.new(gap: gap.to_sym) do |c|
          c.with_item(text: 'Primary', color: :primary)
          c.with_item(text: 'Secondary', color: :secondary)
          c.with_item(text: 'Success', color: :success)
          c.with_item(text: 'Warning', color: :warning)
          c.with_item(text: 'Error', color: :error)
          c.with_item(text: 'Info', color: :info)
        end
      end

      # Mixed styles
      # ---------------
      # Each tag can have independent styling - color, style, size, and rounded.
      def mixed_styles
        render Tags::Component.new do |c|
          c.with_item(text: 'Solid', color: :primary)
          c.with_item(text: 'Outline', color: :primary, style: :outline)
          c.with_item(text: 'Soft', color: :primary, style: :soft)
          c.with_item(text: 'Rounded', color: :success, rounded: true)
          c.with_item(text: 'Large', color: :warning, size: :lg)
          c.with_item(text: 'Small', color: :error, size: :sm)
        end
      end

      # Link tags
      # ---------------
      # Tags can be links when `href` is provided.
      def with_links
        render Tags::Component.new do |c|
          c.with_item(text: 'Documentation', href: '/lookbook', color: :info)
          c.with_item(text: 'GitHub', href: '/lookbook', color: :neutral)
          c.with_item(text: 'API Reference', href: '/lookbook', color: :primary, style: :outline)
        end
      end

      # Custom gap spacing
      # ---------------
      # Use the `gap` parameter to control spacing between tags.
      def gaps
        render_with_template
      end
    end
  end
end
