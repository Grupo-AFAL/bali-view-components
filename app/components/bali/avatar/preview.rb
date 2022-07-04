module Bali
  module Avatar
    class Preview < ApplicationViewComponentPreview
      def default
        render(Avatar::Component.new)
      end
    end
  end
end
