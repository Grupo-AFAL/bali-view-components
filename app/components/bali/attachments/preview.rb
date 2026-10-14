# frozen_string_literal: true

module Bali
  module Attachments
    class Preview < ApplicationViewComponentPreview
      SAMPLE_FILES = [
        { filename: "defect-screenshot.jpg", content_type: "image/jpeg", image: "screenshot.jpg" },
        { filename: "avatar.png", content_type: "image/png", image: "avatar.png" },
        { filename: "minutes.pdf", content_type: "application/pdf", body: "%PDF-1.4\n%%EOF\n" },
        { filename: "Q3 budget reconciliation for the northern region, final version approved by " \
                    "the finance committee.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", body: "PK" },
        { filename: "diagram.svg", content_type: "image/svg+xml",
          body: "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'/>" }
      ].freeze

      # @label Default
      # A landscape screenshot and a square image as thumbnails that open them; a PDF, a
      # spreadsheet with a name long enough to truncate and an SVG (which Active Storage cannot
      # resize) as chips that download them. One more file was attached and never saved, as
      # after a failed validation: it is left out. The empty text waits hidden in the list until
      # a stream removes the last file and leaves it alone in the list.
      #
      # `remove_path:` is the host's DELETE route per attachment, or nil for one the visitor
      # may not remove.
      #
      # @param removable toggle "Remove button on each file"
      def default(removable: true)
        render Bali::Attachments::Component.new(
          attachments: [ *Bali::Attachments::Preview.sample_files, Bali::Attachments::Preview.unsaved_file ],
          remove_path: (->(_attachment) { "/lookbook" } if removable)
        )
      end

      # @label With badge
      # `badge:` draws what the host returns beside each file — here, how the read of each
      # document went.
      def with_badge
        render_with_template(locals: { files: Bali::Attachments::Preview.sample_files })
      end

      # @label Empty
      # The empty text is an item of the list, shown while it is alone, so the stream that
      # removes the last file brings it up. It comes from the locale files unless `empty_text:`
      # says otherwise; `false` renders nothing for an empty list.
      #
      # @param empty_text text "Leave blank for the text from the locale files"
      def empty(empty_text: "")
        render Bali::Attachments::Component.new(attachments: [], empty_text: empty_text.presence)
      end

      # An attachment renders only once it is saved, so the sample files are stored on the
      # first visit and found again after that.
      def self.sample_files
        workout = Workout.joins(:files_attachments).first ||
                  Workout.create!(files: Bali::Attachments::Preview::SAMPLE_FILES.map { |file| sample_upload(file) })
        workout.files.to_a
      end

      def self.sample_upload(file)
        body = file[:body] || Rails.root.join("app/assets/images", file[:image]).binread
        { io: StringIO.new(body), filename: file[:filename], content_type: file[:content_type] }
      end

      def self.unsaved_file
        Workout.new.files.attach(io: StringIO.new("%PDF-1.4"), filename: "never-saved.pdf",
                                 content_type: "application/pdf").first
      end
    end
  end
end
