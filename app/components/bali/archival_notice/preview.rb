# frozen_string_literal: true

module Bali
  module ArchivalNotice
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # @param reason select { choices: [replaced, no_longer_applicable, superseded, expired, other] }
      def default(reason: "replaced")
        movie = archived_movie(reason: reason, by: User.new(name: "Ana García"),
                               successor: Movie.new(name: "Blade Runner 2049"))
        render Bali::ArchivalNotice::Component.new(record: movie, successor_url: "/lookbook")
      end

      # @label Minimal
      # Only the date was recorded: no person, no reason, no successor.
      def minimal
        render Bali::ArchivalNotice::Component.new(record: archived_movie)
      end

      # @label Reopenable
      # A reversible model and a person allowed to reopen: the host passes `unarchive_url:`.
      def reopenable
        movie = archived_movie(reason: "expired", by: User.new(name: "Ana García"))
        render Bali::ArchivalNotice::Component.new(record: movie, unarchive_url: "/lookbook")
      end

      private

      def archived_movie(reason: nil, by: nil, successor: nil)
        Movie.new(name: "Blade Runner").tap do |movie|
          movie.archival = Bali::Archival.new(reason: reason, archived_by: by, successor: successor,
                                              created_at: Time.zone.local(2026, 10, 3, 9))
        end
      end
    end
  end
end
