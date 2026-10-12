# frozen_string_literal: true

module Bali
  module ArchivalForm
    class Component < ApplicationViewComponent
      # @param record [ActiveRecord::Base] the record to archive; includes Bali::Archivable
      # @param successors [ActiveRecord::Relation, nil] the records that may replace it
      # @param url [String] where the form posts
      # @param return_to [String, nil] the path the engine redirects to afterwards
      # @param archival [Bali::Archival, nil] an invalid archival to re-render with its errors
      def initialize(record:, successors:, url:, return_to: nil, archival: nil)
        @record = record
        @successors = successors
        @url = url
        @return_to = Bali::Archival.local_path(return_to)
        @archival = archival || Bali::Archival.new(archivable: record)
      end

      private

      attr_reader :url, :return_to, :archival

      def reason_options
        reasons.map { |reason| [ @record.class.archival_reason_label(reason), reason ] }
      end

      # With no candidates, a reason that needs a successor could never be submitted valid.
      def reasons
        return @record.archival_reasons unless @successors.blank?

        @record.archival_reasons - @record.archival_successor_required_for
      end

      def successor_field?
        @successors.present? && @record.archival_successor_required_for.any?
      end

      # radio-toggle-controller.js splits `data-radio-toggle-value` on ','.
      def successor_reasons = @record.archival_successor_required_for.join(",")

      def successor_options
        @successors.map { |successor| [ Bali::Archival.name_of(successor), successor.id ] }
      end
    end
  end
end
