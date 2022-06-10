# frozen_string_literal: true

module Bali
  module Modal
    class Preview < ApplicationViewComponentPreview
      # Modal
      # ---------------
      # Renders any content inside a modal.
      # @param active toggle
      def default(active: true)
        render Modal::Component.new(active: active) do
          tag.h1 'Modal content', class: 'title is-1'
        end
      end
    end
  end
end
