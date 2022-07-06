# frozen_string_literal: true

module Bali
  module Reveal
    class Preview < ApplicationViewComponentPreview
      def default
        render Reveal::Component.new(opened: false) do |c|
          c.trigger(title: 'Click to see contents')

          c.tag.h1 'Revealed contents'
        end
      end
    end
  end
end
