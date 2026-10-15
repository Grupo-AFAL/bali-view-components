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
      # Twice the 256×128 box the thumbnail is drawn in (`max-w-64 max-h-32`), so a 2x screen
      # shows it sharp at any aspect ratio: a 1920×1080 screenshot comes out 455×256 and is
      # drawn at 227×128. A square limit made it 256×144, drawn at 1.1x.
      THUMBNAIL = { resize_to_limit: [ 512, 256 ] }.freeze

      # @param attachments [Enumerable<ActiveStorage::Attachment>] `record.files`, or any list
      #   of attachments. Only the saved ones render.
      # @param remove_path [Proc, nil] `->(attachment) { path }`, the DELETE route for that
      #   attachment, or nil to leave it without a remove button: who may delete is the host's
      #   policy, and the route its controller. Inside a form or outside one alike: each button
      #   is a `DeleteLink` rendered `in_form: true`.
      # @param badge [Proc, nil] `->(attachment) { html }`, drawn beside each file.
      # @param empty_text [String, false, nil] What the list says while it holds no file
      #   (default: from the locale files). `false` renders nothing for an empty list.
      def initialize(attachments:, remove_path: nil, badge: nil, empty_text: nil, **options)
        @attachments = attachments
        @remove_path = remove_path
        @badge = badge
        @empty_text = empty_text.nil? ? I18n.t("bali_view.attachments.empty") : empty_text
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
