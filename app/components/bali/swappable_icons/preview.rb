# frozen_string_literal: true

module Bali
  module SwappableIcons
    class Preview < ApplicationViewComponentPreview
      def default
        render Bali::SwappableIcons::Component.new do |c|
          c.main_icon('handle')
          c.secondary_icon('handle-alt')
        end
      end
    end
  end
end
