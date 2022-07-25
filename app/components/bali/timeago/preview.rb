# frozen_string_literal: true

module Bali
  module Timeago
    class Preview < ApplicationViewComponentPreview
      # Timeago
      # ----------------------
      # Displays the distance between the given date and now in words
      def default
        render Bali::Timeago::Component.new(10.seconds.ago)
      end
    end
  end
end
