# frozen_string_literal: true

module Bali
  module Skeleton
    class Preview < ApplicationViewComponentPreview
      # @param variant select { choices: [text, paragraph, card, avatar, button, modal, list] }
      # @param size select { choices: [xs, sm, md, lg] }
      # @param lines number
      def default(variant: :paragraph, size: :sm, lines: 3)
        render Bali::Skeleton::Component.new(
          variant: variant.to_sym,
          size: size.to_sym,
          lines: lines.to_i
        )
      end

      # Shows the modal skeleton preset - ideal for loading states in modals
      def modal_skeleton
        render Bali::Skeleton::Component.new(variant: :modal)
      end

      # Shows the list skeleton preset - ideal for loading lists of items
      def list_skeleton
        render Bali::Skeleton::Component.new(variant: :list, lines: 4)
      end

      # Shows all skeleton variants side by side
      def all_variants
        render_with_template
      end
    end
  end
end
