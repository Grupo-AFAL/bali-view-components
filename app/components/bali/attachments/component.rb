# frozen_string_literal: true

module Bali
  module Attachments
    # The files attached to a record: an image as a thumbnail that opens it, anything else as
    # a chip with its name that downloads it, and a remove button where the host allows one.
    #
    #   <%= render Bali::Attachments::Component.new(
    #         attachments: defect.files,
    #         remove_path: ->(attachment) { attachment_path(attachment) if policy(defect).update? },
    #         badge: ->(attachment) { render ReadStatusTag.new(attachment) }
    #       ) %>
    #
    # Each item carries `dom_id(attachment)`, so the host's destroy answers with
    # `turbo_stream.remove attachment`.
    class Component < ApplicationViewComponent
      # Twice the 128px the thumbnail is drawn at (`max-h-32`), so a 2x screen shows it sharp.
      THUMBNAIL = { resize_to_limit: [ 256, 256 ] }.freeze

      # @param attachments [Enumerable<ActiveStorage::Attachment>] `record.files`, or any list
      #   of attachments. Only the saved ones render.
      # @param remove_path [Proc, nil] `->(attachment) { path }`, the DELETE route for that
      #   attachment, or nil to leave it without a remove button: who may delete is the host's
      #   policy, and the route its controller.
      # @param badge [Proc, nil] `->(attachment) { html }`, drawn beside each file — a status tag,
      #   a button of the host's own.
      # @param empty_text [String, nil] What the list says while it holds no file. Without it an
      #   empty list renders nothing.
      def initialize(attachments:, remove_path: nil, badge: nil, empty_text: nil, **options)
        @attachments = attachments
        @remove_path = remove_path
        @badge = badge
        @empty_text = empty_text
        @options = prepend_class_name(options, "attachments-component")
      end

      def render?
        items.any? || empty_text.present?
      end

      private

      attr_reader :empty_text, :options

      # A record whose form failed validation comes back with its new upload still unsaved,
      # and asking that attachment for a URL raises "Cannot get a signed_id for a new record".
      def items
        @items ||= @attachments.select(&:persisted?)
      end

      def remove_path(attachment)
        @remove_path&.call(attachment)
      end

      def badge(attachment)
        @badge&.call(attachment)
      end
    end
  end
end
