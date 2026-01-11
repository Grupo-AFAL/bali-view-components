# frozen_string_literal: true

module Bali
  module Modal
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def default(active: true, size: nil)
        render Modal::Component.new(active: active, size: size) do
          tag.div class: 'space-y-4' do
            safe_join([
                        tag.h3('Modal Title', class: 'text-lg font-bold'),
                        tag.p('This is the modal content. You can put anything here.')
                      ])
          end
        end
      end
    end
  end
end
