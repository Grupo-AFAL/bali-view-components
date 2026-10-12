# frozen_string_literal: true

module Bali
  module ArchivalForm
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Every reason is offered; "Replaced by another" reveals the successor.
      def default
        render Bali::ArchivalForm::Component.new(
          record: Movie.new(name: "Blade Runner"),
          successors: Movie.order(:name).limit(10),
          url: "/lookbook"
        )
      end

      # @label Without successors
      # The model has no candidates, so the reasons that need one are not offered.
      def without_successors
        render Bali::ArchivalForm::Component.new(
          record: Movie.new(name: "Blade Runner"), successors: nil, url: "/lookbook"
        )
      end
    end
  end
end
