# frozen_string_literal: true

module Bali
  module ExchangeableIcons
    class Preview < ApplicationViewComponentPreview
      def default
        render Bali::ExchangeableIcons::Component.new do |c|
          c.main_icon('handle')
          c.secondary_icon('handle-alt')
        end
      end
    end
  end
end
