# frozen_string_literal: true

module Bali
  module Modal
    class Preview < ApplicationViewComponentPreview
      def default
        render(Modal::Component.new) do
          tag.h1 'Modal content', class: 'title is-1'
        end
      end
    end
  end
end
