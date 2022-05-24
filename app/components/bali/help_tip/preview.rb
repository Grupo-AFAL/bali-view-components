# frozen_string_literal: true

# # frozen_string_literal: true

module Bali
  module HelpTip
    class Preview < ApplicationViewComponentPreview
      def default
        render HelpTip::Component.new do
          tag.p 'Hi, this is the help tip content'
        end
      end
    end
  end
end
