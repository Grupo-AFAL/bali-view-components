# frozen_string_literal: true

module Bali
  module ArchivalNotice
    class Component < ApplicationViewComponent
      BASE_CLASSES = "archival-notice-component"

      # @param record [ActiveRecord::Base] a record that includes Bali::Archivable
      # @param successor_url [String, nil] links the successor's name when given
      # @param unarchive_url [String, nil] shows "Reopen", which posts here. Pass it only when the
      #   model is reversible and the person may reopen.
      def initialize(record:, successor_url: nil, unarchive_url: nil, **options)
        @archival = record.archival
        @successor_url = successor_url
        @unarchive_url = unarchive_url
        @options = prepend_class_name(options, BASE_CLASSES)
      end

      def render? = @archival.present?

      private

      attr_reader :archival, :unarchive_url, :options

      def summary
        safe_join([ archived_sentence, reason_sentence, successor_sentence ].compact, " ")
      end

      def archived_sentence
        date = l(archival.created_at.to_date, format: :long)
        return t(".archived", date: date) if archival.archived_by.nil?

        t(".archived_by", date: date, name: Bali::Archival.name_of(archival.archived_by))
      end

      def reason_sentence
        t(".reason", reason: archival.reason_label) if archival.reason.present?
      end

      def successor_sentence
        successor = archival.successor
        return if successor.nil?

        name = Bali::Archival.name_of(successor)
        name = successor_link(name) if @successor_url
        t(".successor_html", successor: name)
      end

      # The link's template breaks lines around the label; inside a sentence that shows as a gap
      # before the full stop.
      def successor_link(name)
        link = render(Bali::Link::Component.new(name: name, href: @successor_url))
        link.gsub(/>\s+/, ">").gsub(/\s+</, "<").html_safe
      end
    end
  end
end
