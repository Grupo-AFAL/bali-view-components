# frozen_string_literal: true

module Bali
  module DocumentEditor
    class Component < ApplicationViewComponent
      attr_reader :title, :initial_content, :document_url, :close_url, :versions_url,
                  :editable, :auto_save, :auto_save_delay, :comments_config,
                  :export, :export_filename, :ai_url, :mentions_url, :mentions

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        title:,
        initial_content:,
        document_url:,
        close_url: nil,
        versions_url: nil,
        editable: true,
        auto_save: true,
        auto_save_delay: 3000,
        comments: nil,
        export: false,
        export_filename: nil,
        ai_url: nil,
        mentions_url: nil,
        mentions: nil
      )
        # rubocop:enable Metrics/ParameterLists
        @title = title
        @initial_content = initial_content
        @document_url = document_url
        @close_url = close_url || document_url
        @versions_url = versions_url
        @editable = editable
        @auto_save = auto_save
        @auto_save_delay = auto_save_delay
        @comments_config = comments
        @export = export
        @export_filename = export_filename || title.parameterize
        @ai_url = ai_url
        @mentions_url = mentions_url
        @mentions = mentions
      end

      def editable?
        @editable
      end

      def comments?
        @comments_config.present?
      end

      def versions?
        @versions_url.present?
      end

      def controller_data
        {
          data: {
            controller: "document-editor",
            document_editor_auto_save_value: auto_save,
            document_editor_auto_save_delay_value: auto_save_delay,
            document_editor_document_url_value: document_url,
            document_editor_versions_url_value: versions_url || "",
            document_editor_toc_open_value: true,
            document_editor_panel_value: ""
          }
        }
      end
    end
  end
end
