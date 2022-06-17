# frozen_string_literal: true

module Bali
  module Loader
    class Preview < ApplicationViewComponentPreview
      # Loader
      # ----------
      # @param text text
      def default(text: 'Loading...')
        render Bali::Loader::Component.new(text: text)
      end
    end
  end
end
